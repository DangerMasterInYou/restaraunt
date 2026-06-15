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

    message.set_content(
        f"Код для входа в «Донер-кебаб»: {verification_code}\n"
        f"Код действителен 10 минут.\n"
        f"Если вы не запрашивали код — просто проигнорируйте это письмо."
    )

    html = f"""\
<!DOCTYPE html>
<html lang="ru">
<body style="margin:0;padding:0;background:#f2f4f7;
             font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
         style="background:#f2f4f7;padding:24px 0;">
    <tr><td align="center">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
             style="max-width:440px;background:#ffffff;border-radius:20px;
                    overflow:hidden;box-shadow:0 6px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:linear-gradient(135deg,#FF6B2C,#F5A623);
                     padding:28px 24px;text-align:center;">
            <div style="font-size:24px;font-weight:700;color:#ffffff;">
              🌯 Донер-кебаб
            </div>
          </td>
        </tr>
        <tr>
          <td style="padding:32px 28px;text-align:center;color:#1a1d21;">
            <div style="font-size:18px;font-weight:600;margin-bottom:8px;">
              Код для входа
            </div>
            <div style="font-size:14px;color:#6b7280;margin-bottom:24px;">
              Нажмите на код, чтобы выделить и скопировать его
            </div>
            <div style="display:inline-block;user-select:all;-webkit-user-select:all;
                        -moz-user-select:all;font-size:34px;font-weight:700;
                        letter-spacing:10px;color:#FF6B2C;background:#fff4ee;
                        border:2px dashed #FF6B2C;border-radius:14px;
                        padding:16px 24px;font-family:'Courier New',monospace;">
              {verification_code}
            </div>
            <div style="font-size:13px;color:#6b7280;margin-top:24px;">
              Код действителен в течение 10 минут.
            </div>
          </td>
        </tr>
        <tr>
          <td style="padding:16px 28px 28px;text-align:center;
                     font-size:12px;color:#9ca3af;border-top:1px solid #eef0f3;">
            Если вы не запрашивали код, просто проигнорируйте это письмо.
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""
    message.add_alternative(html, subtype="html")

    port = settings.smtp.port
    use_tls = port == 465
    start_tls = port == 587
    try:
        await aiosmtplib.send(
            message,
            recipients=[recipient],
            hostname=settings.smtp.server,
            username=settings.smtp.user,
            password=settings.smtp.password,
            port=port,
            use_tls=use_tls,
            start_tls=start_tls,
            timeout=20,
        )
    except Exception as e:
        print(f"Ошибка отправки email: {e}")
        raise
