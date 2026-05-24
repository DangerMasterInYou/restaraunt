#### для алгоритма RS256
```shell
# создает 2048-битный закрытый ключ RSA и сохраняет его в jwt-private.pem.
openssl genrsa -out jwt-private.pem 2048
```

```shell
# извлекает открытый ключ из закрытого и сохраняет его как jwt-public.pem.
openssl rsa -in jwt-private.pem -outform PEM -pubout -out jwt-public.pem
```

#### для алгоритма HS256
```shell
# рандомный ключ 256 битный закодированный в hex
openssl rand -hex 32 > hs256.key
```