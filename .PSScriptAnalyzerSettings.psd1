@{
    ExcludeRules=@('PSUseDeclaredVarsMoreThanAssignment');
    Rules=@{
        'PSAvoidOverwritingBuiltInCmdlets' = @{
            'PowerShellVersion' = @("desktop-5.1.14393.206-windows")
        }
    }
}
