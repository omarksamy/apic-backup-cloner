!/bin/bash

set -x

# Define paths
TOOLKIT_DIR="" # Path to folder of APIC Toolkit
BASE_OUTPUT_DIR="" # Path to folder of Backup
BACKUP_PREFIX="Backup"

# Full path to the apic CLI
APIC_CLI="$TOOLKIT_DIR/apic"

# Login to API Connect
"$APIC_CLI" login --username {Username} --password {Password} \
  --server {APIC Server} \
  --realm {Identity Provider} --mode apim

# Ensure base output directory exists
mkdir -p "$BASE_OUTPUT_DIR"

# Determine next backup folder number
last_number=0
for dir in "$BASE_OUTPUT_DIR"/"$BACKUP_PREFIX "*; do
    if [[ -d "$dir" ]]; then
        dir_name=$(basename "$dir")
        number_part=$(echo "$dir_name" | grep -oP "(?<=${BACKUP_PREFIX} )\d+")
        if [[ "$number_part" =~ ^[0-9]+$ ]]; then
            (( number_part > last_number )) && last_number=$number_part
        fi
    fi
done

# Create new folder name with incremented number and timestamp
new_number=$((last_number + 1))
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
new_backup_dir="$BASE_OUTPUT_DIR/$BACKUP_PREFIX $new_number - $timestamp"
mkdir -p "$new_backup_dir"

clone_products_individually() {
    local ORG=$1
    local OUTPUT_DIR=$2
    mkdir -p "$OUTPUT_DIR"

    SUCCESS_LOG="$OUTPUT_DIR/success.log"
    ERROR_LOG="$OUTPUT_DIR/error.log"
    : > "$SUCCESS_LOG"
    : > "$ERROR_LOG"

    # Get list of products (name + version)
    product_list=$("$APIC_CLI" draft-products:list-all --server {Server} --org "$ORG" --format json)
	echo "$product_list" > "$OUTPUT_DIR/raw-product-list.json"


	# Read each name:version pair from the JSON manually using grep + sed
	grep -oP '"name":\s*"\K[^"]+' "$OUTPUT_DIR/raw-product-list.json" > "$OUTPUT_DIR/names.txt"
	grep -oP '"version":\s*"\K[^"]+' "$OUTPUT_DIR/raw-product-list.json" > "$OUTPUT_DIR/versions.txt"

	paste -d':' "$OUTPUT_DIR/names.txt" "$OUTPUT_DIR/versions.txt" > "$OUTPUT_DIR/product_pairs.txt"

	# Loop over each product
	while IFS=: read -r name version; do
	  echo "Cloning $name:$version ..."
	  PRODUCT_OUTPUT="$OUTPUT_DIR/$name-$version"
	  mkdir -p "$PRODUCT_OUTPUT"

	  if "$APIC_CLI" draft-products:get \
		--server {Server} \
		--org "$ORG" "$name:$version" \
		--output "$PRODUCT_OUTPUT"; then
		echo "$name:$version\n" >> "$SUCCESS_LOG"
	  else
		echo "$name:$version\n" >> "$ERROR_LOG"
	  fi
	done < "$OUTPUT_DIR/product_pairs.txt"
}

clone_apis_individually() {
    local ORG=$1
    local OUTPUT_DIR=$2
    mkdir -p "$OUTPUT_DIR"

    SUCCESS_LOG="$OUTPUT_DIR/success.log"
    ERROR_LOG="$OUTPUT_DIR/error.log"
    : > "$SUCCESS_LOG"
    : > "$ERROR_LOG"

    # Get list of products (name + version)
    api_list=$("$APIC_CLI" draft-apis:list-all --server {Server} --org "$ORG" --format json)
	echo "$api_list" > "$OUTPUT_DIR/raw-api-list.json"


	# Read each name:version pair from the JSON manually using grep + sed
	grep -oP '"name":\s*"\K[^"]+' "$OUTPUT_DIR/raw-api-list.json" > "$OUTPUT_DIR/names.txt"
	grep -oP '"version":\s*"\K[^"]+' "$OUTPUT_DIR/raw-api-list.json" > "$OUTPUT_DIR/versions.txt"

	paste -d':' "$OUTPUT_DIR/names.txt" "$OUTPUT_DIR/versions.txt" > "$OUTPUT_DIR/api_pairs.txt"

	# Loop over each product
	while IFS=: read -r name version; do
	  echo "Cloning $name:$version ..."
	  API_OUTPUT="$OUTPUT_DIR/$name-$version"
	  mkdir -p "$API_OUTPUT"

	  if "$APIC_CLI" draft-apis:get \
		--server {Server} \
		--org "$ORG" "$name:$version" \
		--output "$API_OUTPUT"; then
		echo "$name:$version\n" >> "$SUCCESS_LOG"
	  else
		echo "$name:$version\n" >> "$ERROR_LOG"
	  fi
	done < "$OUTPUT_DIR/api_pairs.txt"
}

# Clone products for each org
clone_products_individually "" "$new_backup_dir/" # First: Name of Organization Second: Subfolder to Save Backup

clone_apis_individually "" "$new_backup_dir/"

echo "Backup complete. Check success.log and error.log under each org folder."
read -p "Press Enter to exit..."
