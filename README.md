
# GCP SSL Certificate Automation

This project contains a script that helps you **automatically create and manage SSL certificates** in **Google Cloud Certificate Manager**.

You don’t need to click around in the console — the script does it for you.

---

# What the Script Does

For every domain listed in `certificate.txt`:

1. Creates a **DNS authorization** (Google’s way to check you own the domain).
2. Shows you the **CNAME record** you must add in your DNS.
3. Creates a **Google-managed SSL certificate** for:
   - `example.com`
   - `*.example.com` (wildcard for all subdomains).
4. Creates a **certificate map** (needed for load balancers).
5. Creates **map entries** for:
   - the root domain (`example.com`)
   - the wildcard (`*.example.com`)

After this, the certificate is ready to be used with a **Google HTTPS Load Balancer**.

---

# Files

- `create_ssl.sh` → the script  
- `certificate.txt` → list of your domains (one per line)  
- `README.md` → this file  

---

# How to Use

### 1. Add Your Domains
Put each domain on a new line inside `certificate.txt`:
```
example.com
mydomain.org
school.edu

````

### 2. Run the Script
Make the script executable and run it:
```bash
chmod +x create_ssl.sh
./create_ssl.sh
````

### 3. Add the DNS Records

The script will show something like this:

```
CNAME record to add in DNS:
name=example.com., rrdatas=[abc123.acme-dns.google.com.]
```
Go to your domain’s DNS provider (or Cloud DNS in GCP) and add this **CNAME record**.
This step proves to Google that you own the domain.

### 4. Wait for SSL to be Issued

Once DNS is set up, Google will automatically issue the SSL certificate.
No need to renew — Google manages it for you.

---

## Example Run
Processing domain: example.com
Creating DNS Authorization for example.com...
🧾 CNAME record to add in DNS:
name=example.com., rrdatas=[abc123.acme-dns.google.com.]

Creating managed certificate for example.com and *.example.com...
Creating certificate map...
Creating cert map entry for root domain...
Creating cert map entry for wildcard domain...
Finished setting up SSL for example.com
---------------------------------------

## Requirements

* Google Cloud SDK (`gcloud`) installed
* Logged in with `gcloud auth login`
* Project set with `gcloud config set project PROJECT_ID`
* **Certificate Manager API** enabled in your project

---

## Notes

* The script will **skip resources** if they already exist.
* Certificates are created in the `global` location.
* You still need to **attach the certificate map** to your HTTPS Load Balancer separately.

