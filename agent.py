import os

import boto3

from erp_client import ERPNextClient

bedrock = boto3.client("bedrock-runtime", region_name=os.environ.get("AWS_REGION", "us-east-1"))
erp = ERPNextClient()

TOOLS_SCHEMA = [
    {
        "toolSpec": {
            "name": "get_services_catalog",
            "description": "Obtiene la lista de servicios disponibles en el negocio con sus precios.",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {},
                    "required": []
                }
            }
        }
    },
    {
        "toolSpec": {
            "name": "check_availability",
            "description": "Verifica citas ocupadas para un especialista en una fecha específica.",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {
                        "practitioner": {"type": "string", "description": "Nombre del médico, barbero o estilista"},
                        "date": {"type": "string", "description": "Fecha en formato YYYY-MM-DD"}
                    },
                    "required": ["practitioner", "date"]
                }
            }
        }
    },
    {
        "toolSpec": {
            "name": "book_appointment",
            "description": "Agenda formalmente una cita para un cliente en ERPNext.",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {
                        "customer_name": {"type": "string", "description": "Nombre completo del cliente"},
                        "phone": {"type": "string", "description": "Número de teléfono o WhatsApp"},
                        "service": {"type": "string", "description": "Nombre exacto del servicio solicitado"},
                        "datetime_str": {"type": "string", "description": "Fecha y hora en formato YYYY-MM-DD HH:MM:SS"}
                    },
                    "required": ["customer_name", "phone", "service", "datetime_str"]
                }
            }
        }
    }
]

SYSTEM_PROMPT = """Eres el asistente virtual inteligente de un negocio local (consultorio / barbería / salón).
Tu objetivo es responder consultas de forma breve, profesional y concretar citas en la agenda del negocio.
Usa las herramientas disponibles para consultar servicios y disponibilidad antes de confirmar una reserva.
No inventes precios ni horarios que no hayan sido retornados por las herramientas."""


def execute_tool(tool_name: str, tool_args: dict):
    if tool_name == "get_services_catalog":
        return erp.list_services()
    if tool_name == "check_availability":
        return erp.check_practitioner_availability(
            practitioner_name=tool_args.get("practitioner", ""),
            date=tool_args.get("date", "")
        )
    if tool_name == "book_appointment":
        return erp.book_appointment(
            customer_name=tool_args.get("customer_name", ""),
            phone=tool_args.get("phone", ""),
            service=tool_args.get("service", ""),
            datetime_str=tool_args.get("datetime_str", "")
        )
    return {"error": "Herramienta no encontrada"}


def process_user_turn(history: list, new_message: str) -> str:
    messages = []
    for h in history:
        messages.append({
            "role": "user" if h["role"] == "user" else "assistant",
            "content": [{"text": h["content"]}]
        })
    messages.append({"role": "user", "content": [{"text": new_message}]})

    #model_id = "anthropic.claude-3-5-haiku-20241022-v1:0"
    model_id = os.environ.get(
    "BEDROCK_MODEL_ID",
    "anthropic.claude-haiku-4-5-20251001-v1:0"
    )

    response = bedrock.converse(
        modelId=model_id,
        messages=messages,
        system=[{"text": SYSTEM_PROMPT}],
        toolConfig={"tools": TOOLS_SCHEMA}
    )

    stop_reason = response["stopReason"]

    if stop_reason == "tool_use":
        assistant_content = response["output"]["message"]["content"]
        messages.append({"role": "assistant", "content": assistant_content})

        tool_results = []
        for block in assistant_content:
            if "toolUse" in block:
                tool_use = block["toolUse"]
                tool_id = tool_use["toolUseId"]
                tool_name = tool_use["name"]
                tool_input = tool_use["input"]

                result_data = execute_tool(tool_name, tool_input)

                tool_results.append({
                    "toolResult": {
                        "toolUseId": tool_id,
                        "content": [{"json": result_data}]
                    }
                })

        messages.append({"role": "user", "content": tool_results})

        final_response = bedrock.converse(
            modelId=model_id,
            messages=messages,
            system=[{"text": SYSTEM_PROMPT}],
            toolConfig={"tools": TOOLS_SCHEMA}
        )
        return final_response["output"]["message"]["content"][0]["text"]

    return response["output"]["message"]["content"][0]["text"]