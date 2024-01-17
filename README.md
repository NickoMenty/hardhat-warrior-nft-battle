
***Set-up***


```
yarn
```
**------------**
**Для теста на Sepolia не нужно ниче тут делать!**
**------------**

***Для деплоя и проверки функций на локальной ноде***


для того шо б быстрее писать
```
yarn global add hardhat-shorthand
```

открываем второй теримнал и запускаем локал ноду
```
yarn hardhat node
```

дальше в первом терминале с каджой новой ноде нужно деплоить по новой
```
hh deploy --network localhost
```
(тут может начать выебываться 99-update-front-end, для этого или же все 3 проекта положить в одну папку, ну или просто удалить этот скрипт)

*Продолжаем деплой и сетап*
ставим атрибуты для каждой нфт
```
yarn hardhat run scripts/set-attributes-for-all.js --network localhost
```

минтим и листим 2 нфт (меняем в скрипте list.js TOKEN_ID)
```
yarn hardhat run scripts/mint.js --network localhost
```
```
yarn hardhat run scripts/list-nft.js --network localhost
```

теперь можем воевать (меняем TOKEN_ID_def, TOKEN_ID_att, RANDOM_INT)

RANDOM_INT - если остаток 0-32 то speed / остаток 33-65 то damage / остаток 66-99 то intelligence

```
yarn hardhat run scripts/start-battle.js --network localhost
```



