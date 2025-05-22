# Configuration schema for OSDCloudCustomBuilder
@{
    type = "object"
    required = @("OrganizationName", "LoggingEnabled", "SchemaVersion")
    properties = @{
        OrganizationName = @{
            type = "string"
            minLength = 1
            maxLength = 100
        }
        OrganizationContact = @{
            type = "string"
        }
        OrganizationEmail = @{
            type = "string"
            pattern = "^[^@]+@[^@]+\.[^@]+$"
        }
        LoggingEnabled = @{
            type = "boolean"
        }
        LogLevel = @{
            type = "string"
            enum = @("Debug", "Info", "Warning", "Error", "Fatal")
        }
        LogRetentionDays = @{
            type = "integer"
            minimum = 1
            maximum = 365
        }
        LogFilePath = @{
            type = "string"
        }
        VerboseLogging = @{
            type = "boolean"
        }
        DebugLogging = @{
            type = "boolean"
        }
        DefaultOSLanguage = @{
            type = "string"
            pattern = "^[a-z]{2}-[a-z]{2}$"
        }
        DefaultOSEdition = @{
            type = "string"
            enum = @("Enterprise", "Professional", "Education")
        }
        DefaultOSLicense = @{
            type = "string"
            enum = @("Retail", "Volume", "OEM")
        }
        SchemaVersion = @{
            type = "string"
            pattern = "^\d+\.\d+$"
        }
    }
}
