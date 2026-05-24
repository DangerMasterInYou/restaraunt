from email.message import EmailMessage

import aiosmtplib

from core.config import settings


async def send_verification_code(
    recipient: str,
    verification_code: str,
) -> None:
    message = EmailMessage()
    message["From"] = settings.smtp.email
    message["To"] = recipient
    message["Subject"] = "Ваш код подтверждения"

    body = f"""
        <h2>Добро пожаловать в Донер-кебаб!</h2>
        <p>Ваш код для входа: <strong>{verification_code}</strong></p>
        <p>Код действителен в течение 10 минут.</p>
        <p>Если вы не запрашивали код, проигнорируйте это письмо.</p>
        """
    message.set_content(body, subtype="html")
    try:
        await aiosmtplib.send(
            message,
            # sender=settings.smtp.email,
            recipients=[recipient],
            hostname=settings.smtp.server,
            username=settings.smtp.user,
            password=settings.smtp.password,
            port=settings.smtp.port,
            # use_tls=True,
            # timeout=10,
        )
    except Exception as e:
        print(f"Ошибка отправки email: {e}")
