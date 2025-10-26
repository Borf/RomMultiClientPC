# Fix-RunasUser.ps1
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName
)

Write-Host "🔍 Verificando conta local: $UserName ..." -ForegroundColor Cyan

# Verifica se o usuário existe
$user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if (-not $user) {
    Write-Host "❌ Usuário '$UserName' não encontrado. Criando novo usuário..." -ForegroundColor Yellow
    $pwd = Read-Host -AsSecureString "Digite uma senha para o novo usuário"
    New-LocalUser -Name $UserName -Password $pwd -FullName $UserName -Description "Usuário recriado para correção de restrições"
    Add-LocalGroupMember -Group "Users" -Member $UserName
    $user = Get-LocalUser -Name $UserName
}

# Mostra status atual
Write-Host "`n📋 Informações atuais:" -ForegroundColor Cyan
$user | Select-Object Name, Enabled, PasswordRequired, PasswordChangeRequired, AccountExpires | Format-List

# 1. Ativar se estiver desativado
if (-not $user.Enabled) {
    Write-Host "🟢 Ativando conta..." -ForegroundColor Green
    Enable-LocalUser -Name $UserName
}

# 2. Corrigir obrigatoriedade de troca de senha
if ($user.PasswordChangeRequired) {
    Write-Host "🔧 Desativando exigência de troca de senha..." -ForegroundColor Green
    Set-LocalUser -Name $UserName -PasswordChangeRequired $false
}

# 3. Corrigir expiração
if ($user.AccountExpires -and ($user.AccountExpires -lt (Get-Date))) {
    Write-Host "🔧 Removendo expiração de conta..." -ForegroundColor Green
    Set-LocalUser -Name $UserName -AccountNeverExpires $true
}

# 4. Verificar senha
Write-Host "`n⚠️ Verificando se a conta '$UserName' tem senha..." -ForegroundColor Cyan
if (-not $user.PasswordRequired) {
    Write-Host "❗ Esta conta não exige senha. Logon via 'runas' pode falhar." -ForegroundColor Yellow
    $setPass = Read-Host "Deseja definir uma senha agora? (S/N)"
    if ($setPass -match '^[sS]') {
        $newPass = Read-Host -AsSecureString "Digite uma nova senha"
        Set-LocalUser -Name $UserName -Password $newPass
        Write-Host "✅ Senha definida com sucesso."
    } else {
        $allowBlank = Read-Host "Deseja permitir logon com senha em branco (menos seguro)? (S/N)"
        if ($allowBlank -match '^[sS]') {
            Write-Host "⚠️ Alterando política de segurança para permitir senhas em branco..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 0
            Write-Host "✅ Política alterada. Reinicie o computador para aplicar."
        }
    }
}

Write-Host "`n✅ Conclusão:"
Write-Host "A conta '$UserName' foi verificada e corrigida."
Write-Host "Tente abrir o client novamente"
