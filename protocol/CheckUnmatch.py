def find_unmatched_braces(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    stack = []
    for line_number, line in enumerate(lines, start=1):
        for char in line:
            if char == '{':
                stack.append(line_number)
            elif char == '}':
                if stack:
                    stack.pop()
                else:
                    print(f"Unmatched closing brace at line {line_number}")
                    return
    if stack:
        print(f"Unmatched opening brace at line {stack[-1]}")
    else:
        print("All braces matched!")

find_unmatched_braces('StarRail.proto')
