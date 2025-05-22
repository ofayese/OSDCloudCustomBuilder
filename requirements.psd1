@{
    # Required modules
    'InvokeBuild' = @{
        Version = '[5.8.0,7.0.0)'  # At least 5.8.0 but less than 7.0.0
        Parameters = @{
            AllowPrerelease = $false
        }
    }
    'ModuleBuilder' = @{
        Version = '[2.0.0,3.0.0)'  # At least 2.0.0 but less than 3.0.0
    }
    'Pester' = @{
        Version = '[5.3.0,6.0.0)'  # At least 5.3.0 but less than 6.0.0
    }
    'OSD' = @{
        Version = '[23.5.2,25.0.0)'  # At least 23.5.2 but less than 25.0.0
    }
    'ThreadJob' = @{
        Version = '[2.0.0,3.0.0)'  # At least 2.0.0 but less than 3.0.0
        Parameters = @{
            AllowPrerelease = $false
        }
    }
}
