import json
import random
import requests
import hashlib

PREPARE_URL = 'https://domain.uz/prepare.php'
COMPLETE_URL = 'https://domain.uz/complete.php'
SERVICE_ID = '12345'
SECRET_KEY = 'secret_key'
CLICK_PAYDOC_ID = '16853761'
MERCHANT_TRANS_ID = '123' #Foydalanuvchi yoki buyurtma raqami

def send_post_request(url, post_data):
    # Avtorizatsiya uchun ehtiyoj bo'lsa
    # headers = {
    #     "Auth": "auth_token"
    # }
    headers = None
    response = requests.post(url, data=post_data, headers=headers)
    return response.json()

def generate_sign_string(data, is_complete_action, merchant_prepare_id=None):
    string_to_hash = (
        f"{data['click_trans_id']}{SERVICE_ID}{SECRET_KEY}{data['merchant_trans_id']}"
        f"{merchant_prepare_id if is_complete_action else ''}{data['amount']}{data['action']}{data['sign_time']}"
    )
    encoded_string = string_to_hash.encode('utf-8')
    return hashlib.md5(encoded_string).hexdigest()

with open('template.json', 'r') as file:
    json_data = json.load(file)

merchant_prepare_id = ''
merchant_prepare_id_old = ''

for k, test in enumerate(json_data):
    test['post']['merchant_trans_id'] = str(random.randint(999999999, 999999999000)) if k == 7 else MERCHANT_TRANS_ID
    test['post']['service_id'] = SERVICE_ID

    if k == 3:
        test['post']['amount'] = 499

    merchant_prepare_id = str(random.randint(999999999, 999999999000)) if k == 9 else merchant_prepare_id_old

    is_complete_action = test['action'] == 'complete'

    test['post']['sign_string'] = '10a250d95b1a6afedcda8360a12a1341' if k in [0, 2] else generate_sign_string(test['post'], is_complete_action, merchant_prepare_id)
    test['post']['error'] = test['sending_error_code']
    test['post']['error_note'] = 'Ok'
    test['post']['click_paydoc_id'] = CLICK_PAYDOC_ID

    url = PREPARE_URL if test['action'] == 'prepare' else COMPLETE_URL

    if is_complete_action:
        test['post']['merchant_prepare_id'] = merchant_prepare_id

    response = send_post_request(url, test['post'])

    if test['action'] == 'prepare' and 'merchant_prepare_id' in response:
        merchant_prepare_id_old = response['merchant_prepare_id']

    if 'success' in response and not response['success']:
        print(f"[xatolik] {test['description']}")
        break
    elif response['error'] != test['expected_error_code']:
        print(f"[xatolik kodi mos kelmadi] {test['description']}")
        break
    else:
        print(f"[ok] {test['description']}")