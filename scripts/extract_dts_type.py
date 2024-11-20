import yaml

class phandle:
    pass

def construct_phandle(loader, node):
    return phandle()

yaml.add_constructor('!phandle', construct_phandle)

def construct_hex(loader, node):
    return [int(n.value, 16) for n in node.value]

yaml.add_constructor('!u64', construct_hex)
yaml.add_constructor('!u8', construct_hex)


def extract_dts_type(output_type_yaml_path: str, input_dts_yaml_path: str):
    def int_value_to_type_name(value):
        if isinstance(value, phandle):
            return 'P'
        elif isinstance(value, int):
            return 'I'
        else:
            raise ValueError(f'Unknown value type: {type(value)}')

    def transform_prop_value_to_type(prop_value):
        if isinstance(prop_value, bool):
            return None
        assert isinstance(prop_value, list)
        if isinstance(prop_value[0], str):
            return None
        assert isinstance(prop_value[0], list)
        # flatten
        prop_type = [int_value_to_type_name(v) for sublist in prop_value for v in sublist]
        if 'P' not in prop_type:
            return None
        else:
            return prop_type
        

    def any_phandle(prop_type):
        if isinstance(prop_type, list):
            for t in prop_type:
                if any_phandle(t):
                    return True
        return prop_type == 'P'
    
    node_type_dict = dict[str, dict[str, any]]()

    def collect_node_types(type_name, node):
        if type_name not in node_type_dict:
            prop_type_dict = {}
            node_type_dict[type_name] = prop_type_dict
        else:
            prop_type_dict = node_type_dict[type_name]
        for prop, value in node.items():
            if prop in prop_type_dict:
                continue

            if isinstance(value, dict):
                next_type_name = prop.split('@')[0] if '@' in prop else prop
                if type_name and 'compatible' not in value:
                    # 不包含 compatible 的节点，type 名称需要从上级节点继承
                    next_type_name = f'{type_name}/{next_type_name}'
                collect_node_types(next_type_name, value)
            else:
                prop_type = transform_prop_value_to_type(value)
                if prop_type:
                    prop_type_dict[prop] = prop_type

    with open(input_dts_yaml_path, 'r') as file:
        data = yaml.load(file, Loader=yaml.Loader)
        collect_node_types('', data[0])

    # 从 node_type_dict 中删掉所有 value 为 {} 的节点
    for type_name in list(node_type_dict.keys()):
        if not node_type_dict[type_name]:
            del node_type_dict[type_name]

    with open(output_type_yaml_path, 'w') as file:
        yaml.dump(node_type_dict, file)

if __name__ == '__main__':
    import sys
    extract_dts_type(sys.argv[1], sys.argv[2])
