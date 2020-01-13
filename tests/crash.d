import core.stdc.string : memset;

void main()
{
    memset(cast(char*) 0x0, 1, 100);
}
