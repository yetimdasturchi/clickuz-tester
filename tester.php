<?php

define('PREPARE_URL', 'https://domain.uz/prepare.php');
define('COMPLETE_URL', 'https://domain.uz/prepare.php');
define('SERVICE_ID', '12345');
define('SECRET_KEY', 'secret_key');
define('CLICK_PAYDOC_ID', '16853761');

define('MERCHANT_TRANS_ID', '123'); //Foydalanuvchi yoki buyurtma raqami

$jsonData = json_decode(file_get_contents('template.json'), true);

$merchantPrepareId = '';
$merchantPrepareIdOld = '';

function sendPostRequest($url, $postData) {
    $curl = curl_init($url);
    curl_setopt($curl, CURLOPT_POST, true);
    curl_setopt($curl, CURLOPT_POSTFIELDS, http_build_query($postData));
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    
    // Avtorizatsiya uchun ehtiyoj bo'lsa
    /*curl_setopt($curl, CURLOPT_HTTPHEADER, [
        'Auth: auth_key'
    ]);*/

    $response = curl_exec($curl);
    curl_close($curl);
    return json_decode($response, true);
}

function generateSignString( $data, $id = false ) {
    return md5(
        $data['click_trans_id'] .
        SERVICE_ID .
        SECRET_KEY .
        $data['merchant_trans_id'] .
        ( $id ? $GLOBALS['merchantPrepareId'] : '' ) .
        $data['amount'] .
        $data['action'] .
        $data['sign_time']
    );
}

foreach ($jsonData as $k => $test) {
    $test['post']['merchant_trans_id'] = ($k == 7) ? rand(999999999, 999999999000) : MERCHANT_TRANS_ID;
    
    $test['post']['service_id'] = SERVICE_ID;

    if ($k == 3) {
        $test['post']['amount'] = 499;
    }

    $merchantPrepareId = ($k == 9) ? rand(999999999, 999999999000) : $merchantPrepareIdOld;

    $isCompleteAction = $test['action'] == 'complete';
    $test['post']['sign_string'] = in_array($k, [0, 2]) ? '10a250d95b1a6afedcda8360a12a1341' : generateSignString($test['post'], $isCompleteAction);
    
    $test['post']['error'] = $test['sending_error_code'];
    $test['post']['error_note'] = 'Ok';
    $test['post']['click_paydoc_id'] = CLICK_PAYDOC_ID;
    
    $url = $test['action'] === 'prepare' ? PREPARE_URL : COMPLETE_URL;
    if ($isCompleteAction) {
        $test['post']['merchant_prepare_id'] = $merchantPrepareId;
    }

    $response = sendPostRequest($url, $test['post']);

    if ($test['action'] === 'prepare' && isset($response['merchant_prepare_id'])) {
        $merchantPrepareIdOld = $response['merchant_prepare_id'];
    }

    if (isset($response['success']) && !$response['success']) {
        echo "[xatolik] " . $test['description'] . "\n";
        break;
    } elseif ($response['error'] != $test['expected_error_code']) {
        echo "[xatolik kodi mos kelmadi] " . $test['description'] . "\n";
        break;
    } else {
        echo "[ok] " . $test['description'] . "\n";
    }
}