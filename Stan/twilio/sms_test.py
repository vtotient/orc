# /usr/bin/env python
# Download the twilio-python library from twilio.com/docs/libraries/python
from twilio.rest import Client

# Victor's number: 7788369671

# Frank's info:
# account_sid = AC9727b1dc0213353ad16a84c7f41f1c67
# auth_token = a9ad2670639dfebee55e9d985854803b
# to: +17789897508
# from: +12267787508

# Find these values at https://twilio.com/user/account
account_sid = "AC9727b1dc0213353ad16a84c7f41f1c67"
auth_token = "a9ad2670639dfebee55e9d985854803b"

client = Client(account_sid, auth_token)

client.api.account.messages.create(
    to="+17789897508",
    from_="+12267787508",
    body="This is a reaaaaaal cool text message. From the man")