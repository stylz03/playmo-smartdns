#!/bin/bash
# Update systemd service with Firebase credentials and Lambda URL

# Stop the service
sudo systemctl stop playmo-smartdns-api

# Firebase credentials JSON (escape it properly)
FIREBASE_JSON='{"type":"service_account","project_id":"playmo-tech","private_key_id":"ec66122a1c5fa8fdea327991891fdd30a80d3411","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCsfPWBn9pU/Zp1\nIaGeD36yNM6+BEa9wrlAO7OuoRqG5wQmGdcXcV6XmRS8UT8KL1bovIzLFhhokvMR\ne4o4pdvHeyqDkM0BjwZuZYJEZDJTAqqzzX59PIg70+DziSp1s9J52QwI2xHeTIAv\ndGEpJFpzimSmSYqszoJrVhEKilh+/aQVA04kBimEFRmWsObTcNqzZR9z92pzv4VL\ntVtlO6MSLjo0Mthz0oW290zipe3Zni6K7wha8itYEL9rwab9je7JmRG8EUddyBzd\nQ9ovhA6ftxDq9gLAm2Id5geROaXaOCJUFWhv5wDQ38cxLAB5nlnf1mzznWz1cGk2\n/CJ/YlfHAgMBAAECggEAMrz3QtAQ21tWKgpgjiwkqqsZ/Y8od/1lnN1y93VwZipi\ncAq92KmCl7lx/gswLgDK4d9E0yCGwYwocAYVHKC9S6qRUO4xP7ogvCyj6xZGL2Dj\nccyK3rAFqwOickDw+nqQ+UK9ZYV7dhauxkbHpeCJst8MyFVts3Nzrbs9fApCCeh6\n0UGJyWGDVJ3CH24zLQARapFjXpH2q1ARMgOUAsbQVK9umVP15xRNWuqEPATQFub+\nvTEM0bXaWQpG8igWC4OYSLem8ZR6RAILvt3szRN+F6q2y7a35fi0IF82Fn3uupFy\n55UgtMfz0+QoLeZ5S511Y3wILterj9xZVKPM4llKUQKBgQDSaMh1JFFdmx925kqA\ngr3R8lHFW8dU/9UA0vjAqvpoG4VvtaeP6ocP6iBGdOzGFdfLQ8DMMdaKhfBk+Onq\n17/voO3OPttJWiRPKb2qcynHU/l4PzCTQyKqXNHdP2C+HnWEidXOrIve6q+zO69n\nsj/8HpeDPyKAPYcD//l/BNr7owKBgQDR3LiyIZP13wMXSve/bjdYLtvfGfMWoYjG\nQbJaNirGAV2c1GayESquTRFA0wEnm/LufySKeOh5qUwYhiMh8+fQhHvH8qlWyzLF\nzRrJhjjTUyqWYZlaZK8pdu97RljZYpLRTOP+36HgfKuFrs4dyK/BatuWZ7NiHUmn\ntHV8K281jQKBgCU2oRWOydE7aVI3IsAd34KtT+cO929CHCMcLSCuXMFi9LOwNiWO\n/jpDV1f+wA28uUDbB9NVkTNIwx6oo36EkA7KsKSEm3YaukdCA6iM27vET2AEFQxG\nmG/3IKr31Z1qd7BsTGNUQxy290JE8R3u+cAWjQeKeAikWSfM8wyTCEPvAoGBAJS7\neI6Oa52Sq08jy4f5ZfHya9OnQXgljZjs0KlMwG3KY/0VL589uWEEr5igsq3OwZIz\nu8MDw8cNrCepUVbr1LwcWNmxakBgDKDRJw3yOW3UAFfJ3fSJbPbXGwzkI24VhXYe\np2toNQKzeKBq7ht/sshColPrNN/xX9UieS1CXzO1AoGARK9PPE4K8QQsGbgr/K3Z\nW3pzA3Q5/FWTAGoDM96SABl6adTOv2VikpbN5CLtob7R4BeuwoJkUiT1aqTpDPwW\nR/+dZTzonFX5EDuVM3yips5dH5WtreYm6oHUDZK2SVE86an5qHQ6TrhlHZXfP81S\n5nJfii7dtzBWa2kdfwK9OJI=\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-fbsvc@playmo-tech.iam.gserviceaccount.com","client_id":"101437745375858188597","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40playmo-tech.iam.gserviceaccount.com","universe_domain":"googleapis.com"}'

# Lambda URL
LAMBDA_URL='https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/'

# Update the service file using Python (safer for JSON)
python3 << PYTHON_SCRIPT
import re

service_file = '/etc/systemd/system/playmo-smartdns-api.service'

# Read the file
with open(service_file, 'r') as f:
    content = f.read()

# Update Firebase credentials
firebase_json = '''{"type":"service_account","project_id":"playmo-tech","private_key_id":"ec66122a1c5fa8fdea327991891fdd30a80d3411","private_key":"-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCsfPWBn9pU/Zp1\\nIaGeD36yNM6+BEa9wrlAO7OuoRqG5wQmGdcXcV6XmRS8UT8KL1bovIzLFhhokvMR\\ne4o4pdvHeyqDkM0BjwZuZYJEZDJTAqqzzX59PIg70+DziSp1s9J52QwI2xHeTIAv\\ndGEpJFpzimSmSYqszoJrVhEKilh+/aQVA04kBimEFRmWsObTcNqzZR9z92pzv4VL\\ntVtlO6MSLjo0Mthz0oW290zipe3Zni6K7wha8itYEL9rwab9je7JmRG8EUddyBzd\\nQ9ovhA6ftxDq9gLAm2Id5geROaXaOCJUFWhv5wDQ38cxLAB5nlnf1mzznWz1cGk2\\n/CJ/YlfHAgMBAAECggEAMrz3QtAQ21tWKgpgjiwkqqsZ/Y8od/1lnN1y93VwZipi\\ncAq92KmCl7lx/gswLgDK4d9E0yCGwYwocAYVHKC9S6qRUO4xP7ogvCyj6xZGL2Dj\\nccyK3rAFqwOickDw+nqQ+UK9ZYV7dhauxkbHpeCJst8MyFVts3Nzrbs9fApCCeh6\\n0UGJyWGDVJ3CH24zLQARapFjXpH2q1ARMgOUAsbQVK9umVP15xRNWuqEPATQFub+\\nvTEM0bXaWQpG8igWC4OYSLem8ZR6RAILvt3szRN+F6q2y7a35fi0IF82Fn3uupFy\\n55UgtMfz0+QoLeZ5S511Y3wILterj9xZVKPM4llKUQKBgQDSaMh1JFFdmx925kqA\\ngr3R8lHFW8dU/9UA0vjAqvpoG4VvtaeP6ocP6iBGdOzGFdfLQ8DMMdaKhfBk+Onq\\n17/voO3OPttJWiRPKb2qcynHU/l4PzCTQyKqXNHdP2C+HnWEidXOrIve6q+zO69n\\nsj/8HpeDPyKAPYcD//l/BNr7owKBgQDR3LiyIZP13wMXSve/bjdYLtvfGfMWoYjG\\nQbJaNirGAV2c1GayESquTRFA0wEnm/LufySKeOh5qUwYhiMh8+fQhHvH8qlWyzLF\\nzRrJhjjTUyqWYZlaZK8pdu97RljZYpLRTOP+36HgfKuFrs4dyK/BatuWZ7NiHUmn\\ntHV8K281jQKBgCU2oRWOydE7aVI3IsAd34KtT+cO929CHCMcLSCuXMFi9LOwNiWO\\n/jpDV1f+wA28uUDbB9NVkTNIwx6oo36EkA7KsKSEm3YaukdCA6iM27vET2AEFQxG\\nmG/3IKr31Z1qd7BsTGNUQxy290JE8R3u+cAWjQeKeAikWSfM8wyTCEPvAoGBAJS7\\neI6Oa52Sq08jy4f5ZfHya9OnQXgljZjs0KlMwG3KY/0VL589uWEEr5igsq3OwZIz\\nu8MDw8cNrCepUVbr1LwcWNmxakBgDKDRJw3yOW3UAFfJ3fSJbPbXGwzkI24VhXYe\\np2toNQKzeKBq7ht/sshColPrNN/xX9UieS1CXzO1AoGARK9PPE4K8QQsGbgr/K3Z\\nW3pzA3Q5/FWTAGoDM96SABl6adTOv2VikpbN5CLtob7R4BeuwoJkUiT1aqTpDPwW\\nR/+dZTzonFX5EDuVM3yips5dH5WtreYm6oHUDZK2SVE86an5qHQ6TrhlHZXfP81S\\n5nJfii7dtzBWa2kdfwK9OJI=\\n-----END PRIVATE KEY-----\\n","client_email":"firebase-adminsdk-fbsvc@playmo-tech.iam.gserviceaccount.com","client_id":"101437745375858188597","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40playmo-tech.iam.gserviceaccount.com","universe_domain":"googleapis.com"}'''

lambda_url = 'https://wjpxg3gay5ba3scu2n3brfrsai0igxyt.lambda-url.us-east-2.on.aws/'

# Replace Firebase credentials line
content = re.sub(
    r'Environment="FIREBASE_CREDENTIALS=.*"',
    f'Environment="FIREBASE_CREDENTIALS={firebase_json}"',
    content
)

# Replace Lambda URL line
content = re.sub(
    r'Environment="LAMBDA_WHITELIST_URL=.*"',
    f'Environment="LAMBDA_WHITELIST_URL={lambda_url}"',
    content
)

# Write back
with open(service_file, 'w') as f:
    f.write(content)

print("Service file updated successfully!")
PYTHON_SCRIPT

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart playmo-smartdns-api
sudo systemctl status playmo-smartdns-api

echo ""
echo "Testing API..."
curl http://localhost:5000/health

