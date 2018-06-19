#include <stdio.h>


__global__ void mykernel(){
  printf("Hello World! \n");
}

int main(void)
{
  mykernel<<<1,1>>>();
  
  return 0;
}
