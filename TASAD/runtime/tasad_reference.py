import argparse
import pathlib

try:
    from .dat_io import flatten, read_int8_dat, reshape, write_uint16_dat
except ImportError:
    from dat_io import flatten, read_int8_dat, reshape, write_uint16_dat

EXP_LUT = {
    0: 32768,
    -1: 12055,
    -2: 4435,
    -3: 1631,
    -4: 600,
    -5: 221,
    -6: 81,
    -7: 30,
    -8: 11,
    -9: 4,
    -10: 1,
}


def trunc_div_toward_zero(value, divisor):
    if divisor <= 0:
        raise ValueError("divisor must be positive")
    if value >= 0:
        return value // divisor
    return -((-value) // divisor)


def tasad_attention(q, k_matrix, return_intermediate=False):
    if len(q) != 64 or len(k_matrix) != 64:
        raise ValueError("Q and K must each have 64 rows")
    if any(len(row) != 64 for row in q) or any(len(row) != 64 for row in k_matrix):
        raise ValueError("Q and K must have shape 64 x 64")

    a = [[0] * 64 for _ in range(64)]
    all_scaled = []
    all_shifted = []
    all_exp = []

    for i in range(64):
        raw_dot = [0] * 64
        for j in range(64):
            acc = 0
            q_row = q[i]
            k_row = k_matrix[j]
            for kk in range(64):
                acc += int(q_row[kk]) * int(k_row[kk])
            raw_dot[j] = acc

        # Official order: scale each dot product first, then find row maximum.
        scaled = [trunc_div_toward_zero(value, 8) for value in raw_dot]
        row_max = max(scaled)
        shifted = [value - row_max for value in scaled]
        exp_values = [0 if value <= -11 else EXP_LUT[value] for value in shifted]
        denominator = sum(exp_values)
        if denominator <= 0:
            raise ArithmeticError(f"row {i}: zero softmax denominator")

        for j in range(64):
            a[i][j] = (exp_values[j] * 32768) // denominator

        if return_intermediate:
            all_scaled.append(scaled)
            all_shifted.append(shifted)
            all_exp.append(exp_values)

    if return_intermediate:
        return a, {
            "scaled": all_scaled,
            "shifted": all_shifted,
            "exp": all_exp,
        }
    return a


def main():
    parser = argparse.ArgumentParser(description="Bit-accurate TASAD software reference")
    parser.add_argument("--q", required=True, help="4096-line signed INT8 Q.dat")
    parser.add_argument("--k", required=True, help="4096-line signed INT8 K.dat")
    parser.add_argument("--out", required=True, help="4096-line unsigned UINT16 output")
    args = parser.parse_args()

    q = reshape(read_int8_dat(args.q, 4096), 64, 64)
    k = reshape(read_int8_dat(args.k, 4096), 64, 64)
    a = tasad_attention(q, k)
    write_uint16_dat(args.out, flatten(a))
    print(f"Wrote 4096 values to {pathlib.Path(args.out)}")


if __name__ == "__main__":
    main()
