# /usr/bin/env python
# Download the twilio-python library from twilio.com/docs/libraries/python
from twilio.rest import Client

# F's info:
# account_sid = xx
# auth_token = xx
# to: +xx
# from: +xx

# V's info:
account_sid = "xx"
auth_token  = "xx"
to_num      = "+xx"
from_num    = "+xx" 

# Find these values at https://twilio.com/user/account
#account_sid = "xx"
#auth_token = "xx"

client = Client(account_sid, auth_token)

def send_text(message):
	mes = str(message)
	client.api.account.messages.create(
    to=to_num,
    from_=from_num,
    body=mes)
