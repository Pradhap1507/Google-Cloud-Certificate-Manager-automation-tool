#!/bin/bash

# Set location
LOCATION="global"

# Input file
CERT_FILE="certificate.txt"

# Loop through domains
while IFS= read -r DOMAIN; do
    [[ -z "$DOMAIN" ]] && continue

    echo "Processing domain: $DOMAIN"
    SAFE_NAME=$(echo "$DOMAIN" | sed 's/\./-/g')

    # Create DNS authorization if it doesn't exist
    echo "Creating DNS Authorization for $DOMAIN..."
    if ! gcloud certificate-manager dns-authorizations describe "${SAFE_NAME}-auth" --location="$LOCATION" &>/dev/null; then
        gcloud certificate-manager dns-authorizations create "${SAFE_NAME}-auth" \
            --domain="$DOMAIN" \
            --type="PER_PROJECT_RECORD" \
            --location="$LOCATION"
    else
        echo "DNS authorization already exists: ${SAFE_NAME}-auth"
    fi

    # Show CNAME to add
    echo "🧾 CNAME record to add in DNS:"
    gcloud certificate-manager dns-authorizations describe "${SAFE_NAME}-auth" \
        --location="$LOCATION" \
        --format="value(dnsResourceRecord)"

    # Create certificate
    echo "Creating managed certificate for $DOMAIN and *.$DOMAIN..."
    if ! gcloud certificate-manager certificates describe "${SAFE_NAME}-cert" --location="$LOCATION" &>/dev/null; then
        gcloud certificate-manager certificates create "${SAFE_NAME}-cert" \
            --domains="$DOMAIN,*.$DOMAIN" \
            --dns-authorizations="${SAFE_NAME}-auth" \
            --location="$LOCATION"
    else
        echo "Certificate already exists: ${SAFE_NAME}-cert"
    fi

    # Create certificate map
    echo "Creating certificate map..."
    if ! gcloud certificate-manager maps describe "${SAFE_NAME}-cert-map" --location="$LOCATION" &>/dev/null; then
        gcloud certificate-manager maps create "${SAFE_NAME}-cert-map" --location="$LOCATION"
    else
        echo "Cert map already exists: ${SAFE_NAME}-cert-map"
    fi

    # Cert map entries
    echo "Creating cert map entry for root domain..."
    gcloud certificate-manager maps entries create "${SAFE_NAME}-root-entry" \
        --map="${SAFE_NAME}-cert-map" \
        --certificates="${SAFE_NAME}-cert" \
        --hostname="$DOMAIN" \
        --location="$LOCATION" || echo "Root entry may already exist."

    echo "Creating cert map entry for wildcard domain..."
    gcloud certificate-manager maps entries create "${SAFE_NAME}-wildcard-entry" \
        --map="${SAFE_NAME}-cert-map" \
        --certificates="${SAFE_NAME}-cert" \
        --hostname="*.$DOMAIN" \
        --location="$LOCATION" || echo "Wildcard entry may already exist."

    echo "Finished setting up SSL for $DOMAIN"
    echo "---------------------------------------"

done < "$CERT_FILE"
