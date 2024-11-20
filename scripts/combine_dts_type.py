import sys
import yaml

def combine_dts_type(output_yaml_path: str, input_yaml_path_list: list[str]):
    node_type_dict = dict[str, dict[str, any]]()

    for input_yaml_path in input_yaml_path_list:
        with open(input_yaml_path, 'r') as file:
            data = yaml.load(file, Loader=yaml.Loader)
            assert isinstance(data, dict)
            for type_name, prop_types in data.items():
                assert isinstance(prop_types, dict)
                if type_name not in node_type_dict:
                    node_type_dict[type_name] = prop_types
                else:
                    node_type_dict[type_name].update(prop_types)
    
    with open(output_yaml_path, 'w') as file:
        yaml.dump(node_type_dict, file)

if __name__ == '__main__':
    combine_dts_type(sys.argv[1], sys.argv[2:])                

