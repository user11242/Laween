import re

file_path = r'C:\Users\PC\Desktop\laween\Laween\presentation-final\index.html'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove data-id tags from title h2 elements to stop them squishing each other!
text = re.sub(r'data-id=\"(groups|design|trust|hub)-title(-2)?\"', '', text)
text = re.sub(r'data-id=\"(groups|design|trust|hub)-desc\"', '', text)

# Remove data-id from the children of mockup-container so they crossfade cleanly without scaling
text = re.sub(r'data-id=\"phone-chassis\"', '', text)
text = re.sub(r'data-id=\"groups-chassis\"', '', text)

# Standardize the mockup-container ID
text = re.sub(r'data-id=\"groups-phone\"', 'data-id=\"phone-mockup\"', text)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Success!')
