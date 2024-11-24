
**Automating GCP Network Infrastructure Using Terraform**

In this lab, I set up network infrastructure on Google Cloud Platform (GCP) using Terraform. This includes installing Terraform, configuring authentication, defining the network infrastructure in a configuration file, and using Terraform commands to create and manage resources. Additionally, I’ll address common issues faced during GCP authentication.

---

#### **Pre-requisites:**
1. A GCP project with the **Compute Engine API** enabled.
2. **Service account** with required IAM roles (e.g., `Compute Network Admin` and `Viewer`) for network management.
3. A **service account key JSON file** downloaded to your local machine.
4. **Terraform** installed on your local machine.

---

### **Steps**

---

### **Step 1: Install Terraform**

1. **Download Terraform** from the official Terraform [downloads page](https://www.terraform.io/downloads.html) based on your OS.
2. **Install Terraform:**
   - **Windows:** Extract the zip file, and add the path of Terraform executable to the system's environment variables.

3. **Verify Installation:**
  
   terraform -v
   ```
   You should see the installed Terraform version if it’s correctly set up.

---

### **Step 2: Set Up GCP Authentication**

To allow Terraform to interact with GCP, we need to authenticate using a service account key JSON file.

1. **Export GCP Credentials Environment Variable:**
  
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-service-account-key.json"
   ```
   Replace `/path/to/your-service-account-key.json` with the actual path to your service account key JSON file. This variable allows Terraform to authenticate using the service account.
   **To stay on the safe side, I’m only providing the syntax without including any specific details. Always remember to keep the service account key private and never share it publicly.**
     

2. **Addressing Authentication Issues**: During this setup, i encounter an **authentication or permissions error (403: Permission Denied)**, which could occur if the service account does not have the necessary permissions on GCP.
   - Ensure the service account has the required IAM roles, especially `Compute Network Admin` for network management.
   - If the issue persists, explicitly specify the credentials in the Terraform configuration file (covered in Step 3).

---

### **Step 3: Create a Terraform Configuration File (main.tf)**

1. In project folder, create a new file named `main.tf`.

2. Write the following Terraform configuration in `main.tf`, including the credentials for authentication: (Attached as configfile+GCP automate.tf )

  
   # Provider configuration for GCP
   provider "google" {
     credentials = file("/path/to/your-service-account-key.json")  # Specify the path to service account key file
     project     = "your-project-id"                               # Replace with your GCP project ID
     region      = "us-central1"                                   # Specify your preferred region
   }

   # Create a custom VPC network
   resource "google_compute_network" "custom_vpc" {
     name                    = "custom-vpc"
     auto_create_subnetworks = false  # Disable auto mode for custom subnet
   }

   # Create a subnet within the VPC
   resource "google_compute_subnetwork" "subnet1" {
     name          = "subnet1"
     ip_cidr_range = "10.0.1.0/24"
     region        = "us-central1"
     network       = google_compute_network.custom_vpc.self_link
   }

   # Create a firewall rule to allow SSH
   resource "google_compute_firewall" "allow_ssh" {
     name    = "allow-ssh"
     network = google_compute_network.custom_vpc.name

     allow {
       protocol = "tcp"
       ports    = ["22"]
     }

     source_ranges = ["0.0.0.0/0"]  # Warning: Allows SSH from any IP
   }
   ```

   **Explanation of configuration:**
   - **Provider block:** Specifies GCP provider with explicit credentials, project ID, and region. Including credentials in the config file resolved the **authentication issue** we encountered.
   - **VPC network:** Defines a custom VPC named `custom-vpc`.
   - **Subnet:** Creates a subnet named `subnet1` within the `custom-vpc` network, with an IP range of `10.0.1.0/24`.
   - **Firewall rule:** Allows SSH (port 22) access within the VPC, with a wide-open IP range (caution required for production environments).

3. **Save** the `main.tf` file.

---

### **Step 4: Initialize Terraform**

Initialize the project to download the necessary plugins and prepare for configuration.


terraform init
```

Expected output:
- Terraform should indicate successful initialization.

---

### **Step 5: Review Configuration with terraform plan**

Run `terraform plan` to see a preview of the actions Terraform will perform based on `main.tf`.


terraform plan
```

Expected output:
- Terraform will display an execution plan showing the resources it will create, including the VPC, subnet, and firewall rule.

---

### **Step 6: Apply the Configuration**

Run `terraform apply` to apply the configuration and create the resources in GCP.


terraform apply
```

1. **Confirm** when prompted by typing `yes`.
2. Wait for Terraform to create the resources.

Expected output:
- Terraform will display the progress of resource creation and confirm completion with "Apply complete!"

---

### **Step 7: Verify Resources in GCP Console**

1. Go to the **GCP Console**: [https://console.cloud.google.com/](https://console.cloud.google.com/).
2. Navigate to **VPC Network > VPC Networks** to confirm the creation of `custom-vpc`.
3. Go to **VPC Network > Subnets** to verify `subnet1`.
4. Check **VPC Network > Firewall** to confirm the presence of the `allow-ssh` rule.

Each of these resources should match your Terraform configuration.

---

### **Step 8: Clean Up Resources (Optional)**

After verifying, you may want to remove the resources to avoid costs.


terraform destroy
```

1. Confirm with `yes` when prompted.
2. Terraform will delete all resources defined in `main.tf`.

---

### **Issues Faced and Solutions**

1. **Permission Denied (403 Error):**
   - **Issue:** Encountered a permission error when trying to create the network resources, indicating that the service account didn't have the necessary permissions.
   - **Solution:** Ensured the service account had the `Compute Network Admin` role. Additionally, including the credentials explicitly in `main.tf` using `credentials = file("/path/to/your-service-account-key.json")` resolved the issue.

2. **GCP Authentication Configuration:**
   - **Issue:** Initial authentication error due to missing or incorrect service account permissions.
   - **Solution:** Explicitly added the credentials path in the `provider` block, which allowed Terraform to access the project successfully.

provider "google" {
  **credentials = file("<path_to_your_service_account_key>.json")**
  project     = "your-project-id"
  region      = "your-region"
}
---

### **Summary**

In this lab, I:
- Installed and configured Terraform for GCP.
- Set up GCP authentication and resolved authentication issues by adding credentials in the configuration file.
- Defined and applied a Terraform configuration (`main.tf`) to create a VPC, subnet, and firewall rule.
- Verified resource creation in the GCP Console and practiced resource cleanup.

This hands-on experience is foundational for automating infrastructure on GCP using Terraform, helping me to build and manage network resources more efficiently.
