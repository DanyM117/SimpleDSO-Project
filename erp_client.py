import os

import requests


class ERPNextClient:
    def __init__(self):
        self.base_url = f"http://{os.environ.get('ERP_HOST', 'api.erp.internal')}"
        api_key = os.environ.get("ERP_API_KEY", "")
        api_secret = os.environ.get("ERP_API_SECRET", "")
        self.headers = {
            "Authorization": f"token {api_key}:{api_secret}",
            "Content-Type": "application/json",
        }

    def list_services(self) -> list:
        try:
            url = f"{self.base_url}/api/resource/Item?filters=[[\"is_sales_item\",\"=\",1]]&fields=[\"name\",\"item_name\",\"standard_rate\"]"
            resp = requests.get(url, headers=self.headers, timeout=4)
            if resp.status_code == 200:
                return resp.json().get("data", [])
            return []
        except requests.RequestException:
            return []

    def check_practitioner_availability(self, practitioner_name: str, date: str) -> list:
        try:
            url = f"{self.base_url}/api/resource/Appointment?filters=[[\"practitioner\",\"=\",\"{practitioner_name}\"],[\"appointment_date\",\"=\",\"{date}\"]]"
            resp = requests.get(url, headers=self.headers, timeout=4)
            if resp.status_code == 200:
                return resp.json().get("data", [])
            return []
        except requests.RequestException:
            return []

    def book_appointment(self, customer_name: str, phone: str, service: str, datetime_str: str) -> dict:
        payload = {
            "doctype": "Appointment",
            "customer_name": customer_name,
            "contact_phone": phone,
            "service_item": service,
            "appointment_datetime": datetime_str,
            "status": "Scheduled",
        }
        try:
            url = f"{self.base_url}/api/resource/Appointment"
            resp = requests.post(url, headers=self.headers, json=payload, timeout=5)
            if resp.status_code == 200:
                return {"status": "success", "id": resp.json().get("data", {}).get("name")}
            return {"status": "error", "code": resp.status_code, "msg": resp.text}
        except requests.RequestException as exc:
            return {"status": "error", "msg": str(exc)}