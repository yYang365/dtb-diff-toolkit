import sys
import yaml

def construct_hex(loader, node):
    return [int(n.value, 16) for n in node.value]

yaml.add_constructor('!u64', construct_hex)
yaml.add_constructor('!u8', construct_hex)

class MyRepresenter(yaml.representer.SafeRepresenter):
    def represent_list(self, data):
        # 检查数组中的所有元素是否都是整数
        if all(isinstance(item, int) for item in data):
            # 都是整数，就排成一行
            return self.represent_sequence('tag:yaml.org,2002:seq', data, flow_style=True)
        else:
            return self.represent_sequence('tag:yaml.org,2002:seq', data, flow_style=False)

yaml.add_representer(list, MyRepresenter.represent_list)

def resolve_dts_phandle(
        output_dts_yaml_file: str, input_dts_yaml_file: str,
        input_phandle_map_file: str, input_combined_type_yaml: str):
    phandle_int_to_path = dict[int, str]()
    with open(input_phandle_map_file, 'r') as file:
        for line in file:
            phandle_int, path = line.strip().split(' ')
            phandle_int_to_path[int(phandle_int, 16)] = path
    
    with open(input_combined_type_yaml, 'r') as file:
        node_type_dict = yaml.load(file, Loader=yaml.Loader)
    
    def replace_phandle(v, t):
        if t == 'P':
            if v not in phandle_int_to_path:
                raise ValueError(f'Unknown phandle: 0x{v:02x}')
            return f'p:{phandle_int_to_path[v]}'
        else:
            return v

    def replace_phandle_in_property_value(value, prop_type):
        if not isinstance(value, list):
            return value
        elif isinstance(value[0], str):
            return value
        elif not isinstance(value[0], list):
            raise ValueError(f'Unknown value type: {type(value[0])}')
        else:
            # flatten
            value_list = [v for sublist in value for v in sublist]
            value_list = [replace_phandle(v, t) for v, t in zip(value_list, prop_type)]
            return [value_list]

    def replace_phandle_in_node(type_name, node, node_path):
        prop_type_dict = node_type_dict.get(type_name, {})
        # 删除 phandle 属性
        if 'phandle' in node:
            del node['phandle']
        for prop, value in node.items():
            if prop in prop_type_dict:
                try:
                    node[prop] = replace_phandle_in_property_value(value, prop_type_dict[prop])
                except ValueError as e:
                    raise ValueError(f'Error in {node_path}:{prop} {e}')
            elif isinstance(value, dict):
                next_type_name = prop.split('@')[0] if '@' in prop else prop
                if type_name and 'compatible' not in value:
                    # 不包含 compatible 的节点，type 名称需要从上级节点继承
                    next_type_name = f'{type_name}/{next_type_name}'
                replace_phandle_in_node(next_type_name, value, f'{node_path}/{prop}')

    with open(input_dts_yaml_file, 'r') as file:
        data = yaml.load(file, Loader=yaml.Loader)
    
    replace_phandle_in_node('', data[0], '')
    
    with open(output_dts_yaml_file, 'w') as file:
        yaml.dump(data, file, Dumper=yaml.Dumper)


if __name__ == '__main__':
    resolve_dts_phandle(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
