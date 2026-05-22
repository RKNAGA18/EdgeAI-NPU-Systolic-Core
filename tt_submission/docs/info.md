<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a 2x2 Weight-Stationary Systolic Array designed for AI matrix multiplication.

## How to test

Set weight_load (uio_in[0]) high to load the 8-bit weights into the processing elements. Then, set compute_en (uio_in[1]) high to stream the 8-bit activations into the array. Read the 32-bit accumulated results from uo_out over 4 clock cycles by toggling the shift_out (uio_in[3]) signal.

## External hardware

None.
