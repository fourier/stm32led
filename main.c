#include "stm32f10x.h"

/*
 * Enum specifying the device LEDs used in LED-operating functions
 */
typedef enum {
    LED_D1,
    LED_D2,
    LED_D3,
    LED_D4
} device_led;


void delay(void)
{
    int i = 0xAFFFF;
    while (i-- > 0) {
        asm("nop");                         /* This stops it optimising code out */
    }
}

void init_leds(void)
{
    /* GPIO structure used to initialize LED port */
    GPIO_InitTypeDef GPIO_InitStructure;
    /* Enable clock on APB2 pripheral bus where LEDs are connected */
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC | RCC_APB2Periph_GPIOD,  ENABLE);
    /* the following configuration of the ports applicable for my HY-STM32:
     * Led D1: PC6(from schematics), means port GPIOC, pin 6
     * Led D2: PC7(from schematics), means port GPIOC, pin 7
     * Led D3: Pd13(from schematics), means port GPIOD, pin 13
     * Led D4: PD6(from schematics), means port GPIOD, pin 6
     */
    /* Initialize pins on port C, leds D1 and D2: */
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7;
    /* select output push-pull mode */
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    /* select GPIO speed */
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOC, &GPIO_InitStructure);

    /* Initialize pins on port D, leds D3 and D4: */
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13 | GPIO_Pin_6;
    /* select output push-pull mode */
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    /* select GPIO speed */
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOD, &GPIO_InitStructure);

    /* initially LEDs off */
    GPIO_ResetBits(GPIOC, GPIO_Pin_6 | GPIO_Pin_7);
    GPIO_ResetBits(GPIOD, GPIO_Pin_13 | GPIO_Pin_6);
}


void toggle_led(device_led led, int toggle)
{
    void (*toggle_func)(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin) = toggle ? GPIO_SetBits : GPIO_ResetBits;
    switch (led)
    {
    case LED_D1:
        toggle_func(GPIOC, GPIO_Pin_6);
        break;
    case LED_D2:
        toggle_func(GPIOC, GPIO_Pin_7);
        break;
    case LED_D3:
        toggle_func(GPIOD, GPIO_Pin_13);
        break;
    case LED_D4:
        toggle_func(GPIOD, GPIO_Pin_6);
        break;
    }
}



int main(void)
{
    init_leds();
    while (1)
    {
        toggle_led(LED_D1,1);
        delay();
        toggle_led(LED_D1,0);
        delay();
        toggle_led(LED_D2,1);
        delay();
        toggle_led(LED_D2,0);
        delay();
        toggle_led(LED_D3,1);
        delay();
        toggle_led(LED_D3,0);
        delay();
        toggle_led(LED_D4,1);
        delay();
        toggle_led(LED_D4,0);
        delay();
    }
}


