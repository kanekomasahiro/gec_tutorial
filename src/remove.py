import argparse


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('--source-lang', type=str, required=True)
    parser.add_argument('--target-lang', type=str, required=True)
    parser.add_argument('--trainpref', type=str, required=True)

    args = parser.parse_args()

    return args


def main(args):
    with open(f'{args.trainpref}.{args.source_lang}') as fs:
        with open(f'{args.trainpref}.{args.target_lang}') as ft:
            with open(f'{args.trainpref}_corrected.{args.source_lang}', 'w') as fws:
                with open(f'{args.trainpref}_corrected.{args.target_lang}', 'w') as fwt:
                    for s, t in zip(fs, ft):
                        if s == t:
                            continue
                        else:
                            fws.write(s)
                            fwt.write(t)


if __name__ == "__main__":
    args = parse_args()
    main(args)
