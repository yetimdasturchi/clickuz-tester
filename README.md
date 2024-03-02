
# clickuz-tester

Unix oilasiga tegishli operatsion tizimlardan foydalanuvchilar uchun click.uz shop apini test qiluvchi scriptlar jamlanmasi.

Quyidagi dasturning alternativasi:

![](https://i.ibb.co/SnqS7Sd/image.png)

## Konstantalar

- PREPARE_URL - premape metodi manzili
- COMPLETE_URL - complete metodi manzili
- SERVICE_ID - click.uz tomonidan berilgan servis manzili
- SECRET_KEY - click.uz servisi uchun kalit
- MERCHANT_TRANS_ID - to'lov qilish uchun buyurtma yoki balans to'ldirish kerak bo'lgan foydalanuvchi idenfikatori

## Bash

*Linux va Macos uchun*

```bash
sudo apt install jq curl #linux
brew install jq curl #macos
```

```bash
bash tester.sh
```

## PHP

```php
/usr/bin/php tester.php
```

## Python

```php
python3 tester.py
```

## Sinov natijasi

```
user@host % python3 tester.py
[ok] Ошибка в подписи при подготовке платежа
[ok] Успешная подготовка платежа
[ok] Ошибка в подписи при подтверждении платежа
[ok] Ошибка в сумме при подтверждении платежа
[ok] Успешное подтверждение платежа
[ok] Повторное подтверждение ранее успешного платежа
[ok] Попытка отмены ранее успешного платежа
[ok] Не найден пользователь/заказ
[ok] Успешная подготовка платежа
[ok] Не найдена транзакция (проверка параметра merchant_prepare_id)
[ok] Успешное подтверждение платежа, complete
[ok] Успешная подготовка платежа
[ok] Отмена платежа
[ok] Повторная отмена платежа
[ok] Повторное подтверждение ранее отмененного платежа
```