#!/bin/bash

PREPARE_URL='https://domain.uz/prepare.php'
COMPLETE_URL='https://domain.uz/complete.php'
SERVICE_ID='12345'
SECRET_KEY='secret_key'
CLICK_PAYDOC_ID='16853761'
MERCHANT_TRANS_ID='123' #Foydalanuvchi yoki buyurtma raqami

sendPostRequest() {
    local url="$1"
    local postData="$2"
    local response=$(curl -X POST -d "$postData" -s "$url")
    #Avtorizatsiyaga ehtiyoj sezilsa
    #local response=$(curl -X POST -d "$postData" -H 'Auth: auth_key' -s "$url")
    echo "$response"
}

generateSignString() {
    local data="$1"
    local id="$2"

    local click_trans_id=$(echo "$data" | jq -r '.click_trans_id')
    local merchant_trans_id=$(echo "$data" | jq -r '.merchant_trans_id')
    local amount=$(echo "$data" | jq -r '.amount')
    local action=$(echo "$data" | jq -r '.action')
    local sign_time=$(echo "$data" | jq -r '.sign_time')

    local signString=$(echo -n "${click_trans_id}${SERVICE_ID}${SECRET_KEY}${merchant_trans_id}$(if [ "$id" == "true" ]; then echo $merchantPrepareId; fi)${amount}${action}${sign_time}" | md5sum | awk '{print $1}')
    echo "$signString"
}

jsonData=$(<template.json)

merchantPrepareId=''
merchantPrepareIdOld=''

for k in $(seq 0 $(($(echo "$jsonData" | jq length) - 1))); do
    echo "Test $(($k+1))"

    test=$(echo "$jsonData" | jq -r ".[$k]")

    merchantTransId=$(if [ "$k" == "7" ]; then echo $(shuf -i 999999999-999999999000 -n 1); else echo $MERCHANT_TRANS_ID; fi)
    test=$(echo "$test" | jq -c ".post.merchant_trans_id = \"$merchantTransId\"")

    test=$(echo "$test" | jq ".post.service_id = $SERVICE_ID")

    if [ "$k" == "3" ]; then
        test=$(echo "$test" | jq ".post.amount = 499")
    fi

    merchantPrepareId=$(if [ "$k" == "9" ]; then echo $(shuf -i 999999999-999999999000 -n 1); else echo $merchantPrepareIdOld; fi)

    isCompleteAction=$(echo "$test" | jq -r '.action == "complete"')

    if [ "$k" == "0" ] || [ "$k" == "2" ]; then
        test=$(echo "$test" | jq '.post.sign_string = "10a250d95b1a6afedcda8360a12a1341"')
    else
        signString=$(generateSignString "$(echo "$test" | jq -c '.post')" "$isCompleteAction")
        test=$(echo "$test" | jq ".post.sign_string = \"$signString\"")
    fi

    test=$(echo "$test" | jq '.post.error = .sending_error_code | .error_note = "Ok" | .click_paydoc_id = "$CLICK_PAYDOC_ID"')

    url=$(if [ "$(echo "$test" | jq -r '.action')" == "prepare" ]; then echo $PREPARE_URL; else echo $COMPLETE_URL; fi)

    if [ "$isCompleteAction" = true ]; then
        test=$(echo "$test" | jq ".post.merchant_prepare_id = $merchantPrepareId")
    fi

    postData=$(echo "$test" | jq -c '.post');
    postData=$(echo "$postData" | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | join("&")')
    response=$(sendPostRequest "$url" "$postData")
    
    success=$(echo "$response" | jq -r '.success')
    error=$(echo "$response" | jq -r '.error')
    expectedErrorCode=$(echo "$test" | jq -r '.expected_error_code')
    description=$(echo "$test" | jq -r '.description')

    if [ "$success" == "false" ]; then
        echo "[xatolik] $description"
        break
    elif [ "$error" != "$expectedErrorCode" ]; then
        echo "Test: $test"
        echo "Response: $response"
        echo "Actual error code: $error"
        echo "Expected error code: $expectedErrorCode"
        echo "[xatolik kodi mos kelmadi] $description"
        break
    else
        echo "[ok] $description"
    fi

    if [ "$(echo "$test" | jq -r '.action')" == "prepare" ] && [ "$(echo "$response" | jq -r '.merchant_prepare_id')" != "null" ]; then
        merchantPrepareIdOld=$(echo "$response" | jq -r '.merchant_prepare_id')
    fi

    echo "------------------------------------------------------------"
    echo ""
done