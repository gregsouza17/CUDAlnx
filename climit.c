#include <stdio.h>
#include <stdlib.h>

#define UPPER_LIMIT 10000000000000 // a very big number

int main (int argc, const char * argv[])
{
    long int_size = sizeof(int);
    for (int i = 1; i < UPPER_LIMIT; i++)
    {
        int c[i];
        for (int j = 0; j < i; j++)
        {
            c[j] = j;
        }
        printf("You can set the array size at %d, which means %ld bytes. \n", c[i-1], int_size*c[i-1]);
    }    
}
