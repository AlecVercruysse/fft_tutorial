# Example FFT Module + Testbench

[![DOI](https://zenodo.org/badge/447786499.svg)](https://zenodo.org/badge/latestdoi/447786499)

This repository contains the SystemVerilog code necessary to run and test a 32-point 16-bit fixed-point FFT in Quartus.

Steps for operation:

1. Ensure you have a working python distribution with Numpy, Matplotlib, and Jupyter installed. It is recommended to use conda/anaconda or Python's virtual environments.

2. Run `rom/twiddle.py` in order to generate twiddle vectors in `rom/twiddle.vectors` and `simulation/modelsim/rom/twiddle.vectors`.

3. Open the `fft_sim_visualization.ipynb` jupyter notebook. In this notebook, you can generate pre-existing (or your own) test-case input sequence. Run the notebook until you have both `simulation/modelsim/rom/test_in.memh` (the simulation input sequence) and `simulation/modelsim/rom/gt_test_out.memh` written.)

4. Open the `fft.qpf` project in Quartus, and run the RTL simulation in ModelSim. This should run `fft_testbench` in `src/testbenches.sv` until the `stop` signal is raised. The console should show no errors, and "FFT test complete." The output of the FFT computation should be written to `simulation/modelsim/rom/test_out.memh`. For a more detailed look at how the FFT is operating, delete the default waveforms and load `simulation/modelsim/debug.do`, which provides most waveforms relevant for debugging.

5. Run the rest of the Jupyter notebook to plot the output of the SystemVerilog FFT implementation and compare it to the Python implementation.

