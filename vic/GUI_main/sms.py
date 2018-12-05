# /usr/bin/env python
# Download the twilio-python library from twilio.com/docs/libraries/python
from twilio.rest import Client

# F's info:
# account_sid = AC9727b1dc0213353ad16a84c7f41f1c67
# auth_token = a9ad2670639dfebee55e9d985854803b
# to: +17789897508
# from: +12267787508

# V's info:
account_sid = "AC5a6c74cbef16fa4d4befa5a7261aa88d"
auth_token  = "a555f07b3c0215f9c8cfee399f2dc5a1"
to_num      = "+17788369671"
from_num    = "+16042658196" 

# Find these values at https://twilio.com/user/account
#account_sid = "AC9727b1dc0213353ad16a84c7f41f1c67"
#auth_token = "a9ad2670639dfebee55e9d985854803b"

client = Client(account_sid, auth_token)

def send_text(message):
	mes = str(message)
	client.api.account.messages.create(
    to=to_num,
    from_=from_num,
    body=mes)