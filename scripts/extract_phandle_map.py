import yaml
import sys

def construct_hex(loader, node):
    return [int(n.value, 16) for n in node.value]

yaml.add_constructor('!u64', construct_hex)
yaml.add_constructor('!u8', construct_hex)


def extract_phandle_map(
        output_phandle_map_file: str,
        input_dts_yaml_file: str):

    phandle_int_to_path = dict[int, str]()

    def collect_phandle_path(node_path, node):
        for prop, value in node.items():
            if prop == 'phandle':
                phandle_int_to_path[value[0][0]] = node_path
            elif isinstance(value, dict):
                collect_phandle_path(f'{node_path}/{prop}', value)

    with open(input_dts_yaml_file, 'r') as file:
        data = yaml.load(file, Loader=yaml.Loader)
        collect_phandle_path('', data[0])

    with open(output_phandle_map_file, 'w') as file:
        for i in sorted(phandle_int_to_path.keys()):
            file.write(f'0x{i:02x} {phandle_int_to_path[i]}\n')

if __name__ == '__main__':
    extract_phandle_map(sys.argv[1], sys.argv[2])
