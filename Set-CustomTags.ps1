param(
    [Parameter(Mandatory = $false, HelpMessage="Category is only used for enhanced tagging. If you don't set a category the script creates a Custom Tag")]
    [string]$Category = $null,

    [Parameter(Mandatory = $true, HelpMessage="Set the name of the Custom / Enhanced tag")]
    [string]$Name,

    [Parameter(Mandatory = $false, HelpMessage="Set the value for the Enhanced Tag. This is not used for a Custom Tag")]
    [string]$Value,

    [Parameter(Mandatory = $false, HelpMessage="By default an existing Enhanced Tag will not be overwritten. Use the -Replace switch to overwrite existing Enhanced Tags values")]
    [Switch]$Replace
)

Add-Type -AssemblyName System.Web

# Decode HTML URI code
if([String]::Empty -ne $Category){
    $Category = [System.Web.HttpUtility]::UrlDecode($Category)
}
$Name = [System.Web.HttpUtility]::UrlDecode($Name)
$Value = [System.Web.HttpUtility]::UrlDecode($Value)

# Set defaul path
if ((Get-WMIObject win32_operatingsystem | Select-Object osarchitecture).osarchitecture -eq "64-bit") {
    $key = "HKLM:\SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data"
}
else {
    $key = "HKLM:\SOFTWARE\Tanium\Tanium Client\Sensor Data"
}

# Function to create key pathing
function New-KeyPath ($path) {
    if ($false -eq (Test-Path $path)) {
        # Check if parrent exists
        $parent = $path.Substring(0, $path.LastIndexOf("\"))
        New-KeyPath -path $parent
		
        Write-Host "Creating: $path"
        try {
            New-Item -Path $path
        }
        catch {
            Write-Host "ERROR: Something went wrong creating $path"
        }
        return 
    }
}

# Switch between Custom or Enhanced Tag
if ([String]::Empty -eq $Category) {
    # Default custom tag
    $TagFolder = "Tags"
}
else {
    # Enhanced tag
    $TagFolder = "EnhancedTags\$Category"
}

# Set key path
$KeyPath = "$key\$TagFolder"

# Create keys if they don't exist
if ($false -eq (Test-Path $KeyPath)) {
    Write-Host "Missing key path: $KeyPath"
    $new = New-KeyPath -Path $KeyPath

    if ($new.Length -gt 0) {
        Write-Host "Created $KeyPath"
    }
}

# Switch between Custom or Enhanced Tag
if ([String]::Empty -eq $Category) {
    # Default custom tag
    if ($KeyPath | Get-Member -Name $Name -MemberType Properties) {
        Write-Host "Custom tag already exists"
        return
    }

    Write-Host "Adding Custom Tag: $Name"
    Set-ItemProperty -Path $KeyPath -Name $Name -Value ""
}
else {
    # Enhanced tag
    try {
        $oldValue = Get-ItemPropertyValue -Path $KeyPath -Name $Name -ErrorAction Stop
        $keyExists = $true
        Write-Host "Old value was: $oldValue"
    }
    catch {
        $keyExists = $false
    }

    if ($true -eq $keyExists -and $false -eq $Replace) {
        Write-Host "Value is already set. Please use the -Replace switch to overwrite the existing value"
        return
    }
    elseif ($true -eq $keyExists -and $true -eq $Replace) {
        Write-Host "Replacing existing value. Replace switch is TRUE"
    }

    Write-Host "Enhanced tag catagory: $Category`nEnhanced tag name: $Name`nEnhanced tag value: $Value"
    Set-ItemProperty -Path $KeyPath -Name $Name -Value $Value
}
