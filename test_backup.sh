#!/bin/bash
TEST_DIR=./test_env
LOG=$TEST_DIR/log
BACKUP=$TEST_DIR/backup
OK=0
FAIL=0
ok()   { echo "  [OK]   $1"; OK=$((OK + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
prepare() {
    rm -rf $TEST_DIR
    mkdir -p $LOG
    for i in 01 02 03 04 05 06 07 08 09 10; do
        dd if=/dev/zero of=$LOG/file_$i bs=1M count=60 status=none
        touch -d "$((11 - 10#$i)) days ago" $LOG/file_$i
    done
}
echo "Тест 1: заполнено 60%, порог 70%"
prepare
./backup.sh $LOG 70 1000 $BACKUP > /dev/null
if [ $(ls $LOG | wc -l) -eq 10 ]; then ok "все 10 файлов на месте"; else fail "некоторые файлы пропали"; fi
if [ ! -d $BACKUP ]; then ok "архив не создан"; else fail "архив создан зря"; fi
echo "Тест 2: заполнено 85%, порог 70%"
prepare
./backup.sh $LOG 70 700 $BACKUP > /dev/null
if [ $(ls $LOG | wc -l) -eq 8 ]; then ok "осталось 8 файлов"; else fail "осталось не 8 файлов"; fi
if [ $(ls $BACKUP | wc -l) -eq 1 ]; then ok "создан 1 архив"; else fail "архив не создан"; fi
echo "Тест 2.1: удалены именно самые старые файлы"
if [ ! -e $LOG/file_01 ] && [ ! -e $LOG/file_02 ]; then ok "file_01 и file_02 удалены"; else fail "старые файлы остались"; fi
if [ -e $LOG/file_03 ] && [ -e $LOG/file_10 ]; then ok "file_03 и file_10 остались"; else fail "удалены не те файлы"; fi
echo "Тест 2.2: архив содержит удалённые файлы"
if [ $(tar -tzf $BACKUP/*.tar.gz | wc -l) -eq 2 ]; then ok "в архиве 2 файла"; else fail "в архиве не 2 файла"; fi
if tar -tzf $BACKUP/*.tar.gz | grep -q file_01; then ok "в архиве есть file_01"; else fail "file_01 нет в архиве"; fi
echo "Тест 3: заполнено 60%, порог 30%"
prepare
./backup.sh $LOG 30 1000 $BACKUP > /dev/null
if [ $(ls $LOG | wc -l) -eq 5 ]; then ok "осталось 5 файлов (30%)"; else fail "осталось не 5 файлов"; fi
echo "Тест 4: LAB1_MAX_COMPRESSION=1, заполнено 85%, порог 70%"
prepare
LAB1_MAX_COMPRESSION=1 ./backup.sh $LOG 70 700 $BACKUP > /dev/null
if [ $(ls $BACKUP/*.tar.lzma | wc -l) -eq 1 ]; then ok "создан архив .tar.lzma"; else fail "архив .tar.lzma не создан"; fi
if [ ! -e $BACKUP/*.tar.gz ]; then ok "архива .tar.gz нет"; else fail "создан лишний .tar.gz"; fi
if [ $(tar --lzma -tf $BACKUP/*.tar.lzma | wc -l) -eq 2 ]; then ok "lzma-архив читается, в нём 2 файла"; else fail "lzma-архив не открывается или не 2 файла"; fi
if [ $(ls $LOG | wc -l) -eq 8 ]; then ok "из папки удалены 2 файла"; else fail "осталось не 8 файлов"; fi
rm -rf $TEST_DIR
echo
echo "Итого: успешно $OK, провалено $FAIL"
