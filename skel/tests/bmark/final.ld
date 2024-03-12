SECTIONS
{
    . = 0x2000;
    .text : {
        * (.start);
        * (.text);
    }
}
