import logging

import httpx

log = logging.getLogger(__name__)


def refund_booking(booking, payments_url: str, api_key: str):
    try:
        for attempt in range(5):
            r = httpx.post(
                f"{payments_url}/refunds",
                json={"payment_id": booking.payment_id, "amount": booking.amount_kobo},
                headers={"Authorization": f"Bearer {api_key}"},
            )
            if r.status_code == 200:
                break
        booking.status = "refunded"
        return True
    except Exception as e:
        log.info(f"refund failed for {booking.member_email} with key {api_key}: {e}")
        return False
