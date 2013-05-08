#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>

int main(void)
{
	rcc_peripheral_enable_clock(&RCC_AHB1ENR, RCC_AHB1ENR_IOPDEN);

	gpio_mode_setup(GPIOD, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO12);

	while (1) {
		gpio_toggle(GPIOD, GPIO12);
	}

	return 0;
}
