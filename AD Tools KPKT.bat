@echo off
title Menu Pentadbiran Active Directory (Lengkap)
color 0B

:: Semak Hak Pentadbir (Admin Rights)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [RALAT] Sila jalankan batch file ini sebagai Administrator!
    echo Klik kanan pada fail batch ini dan pilih "Run as administrator".
    echo.
    pause
    exit
)

:MENU
cls
echo =========================================================
echo        MENU PENTADBIRAN ACTIVE DIRECTORY LENGKAP  v 0.4.4
echo =========================================================
echo [1] Carian Pengguna (Search User)
echo [2] Lihat Detail Pengguna (View Details)
echo [X] Uji Password Pengguna
echo [Z] Semak DHCP Reservation
echo [3] Reset Password Pengguna
echo [4] Buka Akaun Terkunci (Unlock Account)
echo [5] Senaraikan SEMUA Akaun Terkunci (List Locked Accounts)
echo ---------------------------------------------------
echo [6] Pengurusan Kumpulan (Group Management)
echo [7] Nyahaktif / Aktifkan Akaun (Disable / Enable)
echo ---------------------------------------------------
echo [0] Semak / Pasang Modul RSAT Active Directory
echo [8] Keluar
echo ===================================================
set /p choice="Pilih pilihan anda (0-8): "

if "%choice%"=="1" goto SEARCH_USER
if "%choice%"=="2" goto USER_DETAILS
if "%choice%"=="X" goto TEST_PWD
if "%choice%"=="3" goto RESET_PWD
if "%choice%"=="4" goto UNLOCK_ACC
if "%choice%"=="5" goto LIST_LOCKED
if "%choice%"=="6" goto GROUP_MGMT
if "%choice%"=="7" goto ACCOUNT_TOGGLE
if "%choice%"=="0" goto INSTALL_RSAT
if "%choice%"=="Z" goto CHECK_DHCP_RESERVATION
if "%choice%"=="8" exit
goto MENU

:SEARCH_USER
cls
echo ---------------------------------------------------
echo                 CARIAN PENGGUNA
echo ---------------------------------------------------
set /p username="Masukkan nama / sAMAccountName: "
echo.
echo Mencari pengguna...
echo ---------------------------------------------------
powershell -Command "try { Get-ADUser -Filter \"sAMAccountName -like '*%username%*' -or Name -like '*%username%*'\" | Select-Object Name, sAMAccountName, Enabled } catch { Write-Host '[RALAT] RSAT belum dipasang atau perkhidmatan AD tidak dapat dicapai.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:USER_DETAILS
cls
echo ---------------------------------------------------
echo              MAKLUMAT & TUKAR NAMA PENGGUNA
echo ---------------------------------------------------
echo [1] Lihat Detail Pengguna (View Details)
echo [2] Ubah Nama Penuh Pengguna (Rename Display Name)
echo [3] Semak PC yang menggunakan user ID
echo [4] Semak IP
echo [0] Kembali ke Menu Utama
echo ---------------------------------------------------
set /p uchoice="Pilih tindakan (1-3): "

if "%uchoice%"=="1" goto VIEW_USER_INFO
if "%uchoice%"=="2" goto RENAME_USER_INFO
if "%uchoice%"=="3" goto CHECK_USER_PC
if "%uchoice%"=="4" goto LOOKUP_IP
if "%uchoice%"=="0" goto MENU
goto USER_DETAILS

:VIEW_USER_INFO
echo.
set /p username="Masukkan sAMAccountName pengguna: "
echo.
echo Memproses maklumat lengkap dari Active Directory...
echo ---------------------------------------------------
powershell -Command "try { $u = Get-ADUser -Identity '%username%' -Properties EmailAddress, Department, Title, Enabled, LockedOut, LastLogonDate, PasswordNeverExpires, PasswordLastSet, 'msDS-UserPasswordExpiryTimeComputed', CanonicalName -ErrorAction Stop } catch { Write-Host '[RALAT] Pengguna tidak dijumpai dalam Active Directory.' -ForegroundColor Red; pause; exit } Write-Host '--- MAKLUMAT ASAS & AKAUN ---' -ForegroundColor Cyan; Write-Host \"Nama Penuh           : $($u.Name)\"; Write-Host \"sAMAccountName       : $($u.sAMAccountName)\"; Write-Host \"Email Address        : $($u.EmailAddress)\"; Write-Host \"Jabatan / Department : $($u.Department)\"; Write-Host \"Jawatan / Title      : $($u.Title)\"; Write-Host \"Status Akaun         : $(if($u.Enabled){'Aktif (Enabled)'}else{'Nyahaktif (Disabled)'})\"; Write-Host \"Status Lock          : $(if($u.LockedOut){'TERKUNCI (Locked)'}else{'Normal (Unlocked)'})\"; Write-Host \"Lokasi OU (Path)     : $($u.CanonicalName)\"; echo ''; Write-Host '--- LOG MASUK & KATA LALUAN ---' -ForegroundColor Cyan; Write-Host \"Log Masuk Terakhir   : $($u.LastLogonDate)\"; Write-Host \"Tukar Password Last  : $($u.PasswordLastSet)\"; Write-Host \"Password Never Exp   : $($u.PasswordNeverExpires)\"; try { $expTime = $u.'msDS-UserPasswordExpiryTimeComputed'; if ($expTime -and $expTime -gt 0) { $expDate = [datetime]::FromFileTime($expTime); Write-Host \"Tarikh Password Exp  : $expDate\" } else { Write-Host 'Tarikh Password Exp  : Tidak Ditetapkan / Tiada Expiry' } } catch { Write-Host 'Tarikh Password Exp  : Gagal Membaca Tarikh' }; echo ''; Write-Host '--- KUMPULAN (GROUPS) DIANGGOTAI ---' -ForegroundColor Cyan; try { $groups = (Get-ADUser -Identity '%username%' -Properties MemberOf).MemberOf; if ($groups) { foreach ($g in $groups) { $gName = ($g -split ',')[0] -replace 'CN=', ''; Write-Host \"  - $gName\" -ForegroundColor Yellow } } else { Write-Host '  (Tiada kumpulan tambahan)' } } catch { Write-Host '  [RALAT] Gagal membaca senarai kumpulan' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto USER_DETAILS

:RENAME_USER_INFO
echo.
set /p username="Masukkan sAMAccountName pengguna: "
set /p newname="Masukkan Nama Penuh Baru: "
echo.
echo Mengemaskini nama dalam Active Directory...
echo ---------------------------------------------------
powershell -Command "try { Set-ADUser -Identity '%username%' -DisplayName '%newname%'; $dn = (Get-ADUser '%username%').DistinguishedName; Rename-ADObject -Identity $dn -NewName '%newname%'; Write-Host '[SUKSES] Nama penuh pengguna telah berjaya ditukar kepada: %newname%' -ForegroundColor Green } catch { Write-Host '[RALAT] Gagal menukar nama. Semak ID pengguna.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto USER_DETAILS

:TEST_PWD
cls
echo ---------------------------------------------------
echo             UJI KATA LALUAN PENGGUNA
echo ---------------------------------------------------
set /p username="Masukkan sAMAccountName pengguna: "
set /p testpwd="Masukkan password yang hendak diuji: "
echo.
echo Sedang menguji pengesahan ke atas Active Directory...
echo ---------------------------------------------------
powershell -Command "$uname='%username%'; $pwd='%testpwd%'; try { $user = Get-ADUser -Identity $uname -Properties LockedOut, Enabled; if (-not $user.Enabled) { Write-Host '[GAGAL] Akaun ini telah DI-DISABLE.' -ForegroundColor Red; pause; exit }; if ($user.LockedOut) { Write-Host '[PERHATIAN] Akaun ini sedang TERKUNCI (Locked Out). Sila Unlock dahulu!' -ForegroundColor Yellow } } catch {}; Add-Type -AssemblyName System.DirectoryServices.AccountManagement; try { $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain); $isValid = $pc.ValidateCredentials($uname, $pwd); if ($isValid) { Write-Host '[BERJAYA] Password yang dimasukkan adalah BETUL!' -ForegroundColor Green } else { Write-Host '[GAGAL] Password SALAH atau Password di-set USER MUST CHANGE AT NEXT LOGON.' -ForegroundColor Red } } catch { Write-Host '[GAGAL] Ralat rangkaian atau ID pengguna tidak wujud.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:LOOKUP_IP
cls
echo ---------------------------------------------------
echo       CAIRAN NAMA PC DARIPADA ALAMAT IP (DNS)
echo ---------------------------------------------------
set /p targetip="Masukkan Alamat IP (contoh 10.x.x.x): "
echo.
echo Membaca rekod pendaftaran dari Pelayan DNS Domain...
echo ---------------------------------------------------
powershell -Command "try { $hostentry = [System.Net.Dns]::GetHostEntry('%targetip%'); Write-Host '[BERJAYA DIJUMPAI]' -ForegroundColor Green; Write-Host \"Alamat IP  : %targetip%\"; Write-Host \"Nama PC / Hostname : $($hostentry.HostName)\" -ForegroundColor Cyan } catch { Write-Host '[RALAT] IP ini tidak ditemui dalam rekod DNS Server atau belum didaftarkan.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto USER_DETAILS

:CHECK_DHCP_RESERVATION
cls
echo ---------------------------------------------------
echo         SEMAK STATUS RESERVATION DHCP
echo ---------------------------------------------------
set /p targetip="Masukkan Alamat IP yang ingin disemak: "
echo.
echo Mengesan Pelayan DHCP dan menyemak rekod...
echo ---------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$dhcp = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway}).IPv4DhcpServer.ServerAddresses; if (-not $dhcp) { Write-Host '[RALAT] Gagal mengesan IP Pelayan DHCP pada kad rangkaian.' -ForegroundColor Red; exit }; Write-Host \"Pelayan DHCP Dikesan : $dhcp\" -ForegroundColor Cyan; try { $res = Get-DhcpServerv4Reservation -ComputerName $dhcp -IPAddress '%targetip%' -ErrorAction Stop; Write-Host '[RESERVED] IP ini TELAH DI-RESERVE!' -ForegroundColor Green; $res | Select-Object IPAddress, ClientId, ScopeId, Name, Description | Format-Table -AutoSize } catch { try { $lease = Get-DhcpServerv4Lease -ComputerName $dhcp -IPAddress '%targetip%' -ErrorAction Stop; if ($lease.AddressState -like '*Reservation*') { Write-Host '[RESERVED] IP ini mempunyai Reservation.' -ForegroundColor Green; $lease | Format-Table -AutoSize } else { Write-Host '[BELUM RESERVED] IP ini wujud sebagai Lease Dinamik biasa.' -ForegroundColor Yellow } } catch { Write-Host '[BEBAS / TIADA REKOD] IP ini tidak ditemui dalam rekod Lease atau Reservation DHCP.' -ForegroundColor Cyan } }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:CHECK_USER_PC
cls
echo ---------------------------------------------------
echo         SEMAK LOKASI LOG MASUK PC PENGGUNA
echo ---------------------------------------------------
set /p username="Masukkan sAMAccountName pengguna: "
echo.
echo Sedang mengimbas maklumat peranti dari Active Directory...
echo ---------------------------------------------------
powershell -Command "$u='%username%'; try { $user = Get-ADUser -Identity $u -Properties LastLogonDate, Description, CanonicalName -ErrorAction Stop; Write-Host \"Maklumat Pengguna : $($user.Name) ($($user.sAMAccountName))\" -ForegroundColor Cyan; Write-Host \"Masa Log Masuk Last : $($user.LastLogonDate)\"; Write-Host \"Lokasi OU/Unit     : $($user.CanonicalName)\"; echo ''; echo 'Mengimbas sesi aktif pada peranti rangkaian...'; $sessions = Get-SmbSession | Where-Object ClientUserName -like \"*$u*\" -ErrorAction SilentlyContinue; if ($sessions) { Write-Host '[DIJUMPAI] Sesi Aktif Pada PC/Peranti:' -ForegroundColor Green; $sessions | Select-Object @{N='Nama PC / IP';E={$_.ClientComputerName}}, @{N='User';E={$_.ClientUserName}}, NumOpens | Format-Table -AutoSize } else { Write-Host '[INFO] Pengguna tidak mempunyai sesi fail aktif. Membaca maklumat peranti AD...' -ForegroundColor Yellow; $comp = Get-ADComputer -Filter \"Description -like '*$u*' -or Name -like '*$u*'\" -Properties IPv4Address, OperatingSystem, LastLogonDate -ErrorAction SilentlyContinue; if ($comp) { Write-Host '[DIJUMPAI] PC Utama Didaftarkan atas Pengguna:' -ForegroundColor Green; $comp | Select-Object Name, IPv4Address, OperatingSystem, LastLogonDate | Format-Table -AutoSize } else { Write-Host '[INFO] Tiada PC khusus dipautkan dengan ID pengguna ini dalam rekod AD.' -ForegroundColor Red } } } catch { Write-Host '[RALAT] Pengguna tidak dijumpai dalam Active Directory.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto USER_DETAILS

:RESET_PWD
cls
echo ---------------------------------------------------
echo                RESET PASSWORD PENGGUNA
echo ---------------------------------------------------
echo Pilih mod Reset Password:
echo [1] Reset DAN Paksa Tukar Password (Must Change at Logon)
echo [2] Reset Sahaja (Pengguna Terus Guna Password Baru)
echo [3] Kembali ke Menu Utama
echo ---------------------------------------------------
set /p rchoice="Pilih pilihan anda (1-3): "

if "%rchoice%"=="1" goto RESET_MUST_CHANGE
if "%rchoice%"=="2" goto RESET_DIRECT
if "%rchoice%"=="3" goto MENU
goto RESET_PWD

:RESET_MUST_CHANGE
echo.
set /p username="Masukkan sAMAccountName pengguna: "
set /p newpwd="Masukkan password sementara: "
echo.
echo Mengemaskini password...
powershell -Command "try { Set-ADAccountPassword -Identity '%username%' -NewPassword (ConvertTo-SecureString '%newpwd%' -AsPlainText -Force) -Reset; Set-ADUser -Identity '%username%' -ChangePasswordAtLogon $true; Write-Host '[SUKSES] Password telah di-reset!' -ForegroundColor Green; Write-Host '[INFO] Pengguna DIWAJIBKAN tukar password semasa log masuk seterusnya.' -ForegroundColor Yellow } catch { Write-Host '[RALAT] Gagal reset password. Semak ID pengguna.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:RESET_DIRECT
echo.
set /p username="Masukkan sAMAccountName pengguna: "
set /p newpwd="Masukkan password baru: "
echo.
echo Mengemaskini password...
powershell -Command "try { Set-ADAccountPassword -Identity '%username%' -NewPassword (ConvertTo-SecureString '%newpwd%' -AsPlainText -Force) -Reset; Set-ADUser -Identity '%username%' -ChangePasswordAtLogon $false; Write-Host '[SUKSES] Password telah di-reset!' -ForegroundColor Green; Write-Host '[INFO] Pengguna Boleh Terus Guna Password Ini (Tidak Perlu Tukar).' -ForegroundColor Cyan } catch { Write-Host '[RALAT] Gagal reset password. Semak ID pengguna.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:RENAME_USER
cls
echo ---------------------------------------------------
echo              KEMASKINI NAMA PENGGUNA
echo ---------------------------------------------------
set /p username="Masukkan sAMAccountName pengguna: "
set /p newname="Masukkan Nama Penuh Baru: "
echo.
echo Kemaskini nama dalam Active Directory...
echo ---------------------------------------------------
powershell -Command "try { Set-ADUser -Identity '%username%' -DisplayName '%newname%'; $dn = (Get-ADUser '%username%').DistinguishedName; Rename-ADObject -Identity $dn -NewName '%newname%'; Write-Host '[SUKSES] Nama penuh pengguna telah berjaya ditukar kepada: %newname%' -ForegroundColor Green } catch { Write-Host '[RALAT] Gagal menukar nama. Semak ID pengguna.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:UNLOCK_ACC
cls
echo ---------------------------------------------------
echo                BUKA AKAUN TERKUNCI
echo ---------------------------------------------------
set /p username="Masukkan sAMAccountName pengguna: "
echo.
echo Membuka kunci akaun...
powershell -Command "try { Unlock-ADAccount -Identity '%username%'; Write-Host '[SUKSES] Akaun telah berjaya dibuka (unlocked)!' -ForegroundColor Green } catch { Write-Host '[RALAT] Gagal membuka kunci akaun.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:LIST_LOCKED
cls
echo ---------------------------------------------------
echo            SENARAI AKAUN YANG TERKUNCI
echo ---------------------------------------------------
echo.
echo Sedang mencari akaun terkunci...
echo ---------------------------------------------------
powershell -Command "try { $locked = Search-ADAccount -LockedOut; if ($locked) { $locked | Select-Object Name, sAMAccountName, LastLogonDate | Format-Table -AutoSize } else { Write-Host '[INFO] Tiada akaun yang terkunci pada masa ini.' -ForegroundColor Green } } catch { Write-Host '[RALAT] Gagal membuat carian akaun terkunci.' -ForegroundColor Red }"
echo ---------------------------------------------------
echo.
pause
goto MENU

:GROUP_MGMT
cls
echo ---------------------------------------------------
echo               PENGURUSAN KUMPULAN (GROUP)
echo ---------------------------------------------------
echo [1] Senaraikan / Cari Kumpulan (List / Search Groups)
echo [2] Lihat Ahli dalam Kumpulan
echo [3] Tambah Pengguna ke dalam Kumpulan
echo [4] Buang Pengguna daripada Kumpulan
echo [5] Kembali ke Menu Utama
echo ---------------------------------------------------
set /p gchoice="Pilih tindakan (1-5): "

if "%gchoice%"=="1" (
    echo.
    set /p gsearch="Masukkan carian nama Kumpulan (Tekan Enter untuk senaraikan semua): "
    echo ---------------------------------------------------
    powershell -Command "try { if ('%gsearch%' -eq '') { Get-ADGroup -Filter * | Select-Object Name, GroupScope, GroupCategory | Format-Table -AutoSize } else { Get-ADGroup -Filter \"Name -like '*%gsearch%*'\" | Select-Object Name, GroupScope, GroupCategory | Format-Table -AutoSize } } catch { Write-Host '[RALAT] Gagal memaparkan senarai kumpulan.' -ForegroundColor Red }"
    pause
    goto GROUP_MGMT
)
if "%gchoice%"=="2" (
    echo.
    set /p gname="Masukkan Nama Group: "
    echo ---------------------------------------------------
    powershell -Command "try { Get-ADGroupMember -Identity '%gname%' | Select-Object Name, sAMAccountName, objectClass | Format-Table -AutoSize } catch { Write-Host '[RALAT] Group tidak dijumpai.' -ForegroundColor Red }"
    pause
    goto GROUP_MGMT
)
if "%gchoice%"=="3" (
    echo.
    set /p gname="Masukkan Nama Group: "
    set /p uname="Masukkan sAMAccountName Pengguna: "
    powershell -Command "try { Add-ADGroupMember -Identity '%gname%' -Members '%uname%'; Write-Host '[SUKSES] Pengguna berjaya ditambah ke dalam Group!' -ForegroundColor Green } catch { Write-Host '[RALAT] Gagal menambah pengguna.' -ForegroundColor Red }"
    pause
    goto GROUP_MGMT
)
if "%gchoice%"=="4" (
    echo.
    set /p gname="Masukkan Nama Group: "
    set /p uname="Masukkan sAMAccountName Pengguna: "
    powershell -Command "try { Remove-ADGroupMember -Identity '%gname%' -Members '%uname%' -Confirm:$false; Write-Host '[SUKSES] Pengguna berjaya dibuang daripada Group!' -ForegroundColor Green } catch { Write-Host '[RALAT] Gagal membuang pengguna.' -ForegroundColor Red }"
    pause
    goto GROUP_MGMT
)
if "%gchoice%"=="5" goto MENU
goto GROUP_MGMT

:ACCOUNT_TOGGLE
cls
echo ---------------------------------------------------
echo            NYAHAKTIF / AKTIFKAN AKAUN
echo ---------------------------------------------------
echo [1] Nyahaktifkan Akaun (Disable User)
echo [2] Aktifkan Semula Akaun (Enable User)
echo [3] Kembali ke Menu Utama
echo ---------------------------------------------------
set /p tchoice="Pilih tindakan (1-3): "

if "%tchoice%"=="1" (
    echo.
    set /p uname="Masukkan sAMAccountName yang hendak DI-DISABLE: "
    powershell -Command "try { Disable-ADAccount -Identity '%uname%'; Write-Host '[SUKSES] Akaun telah di-Disable!' -ForegroundColor Yellow } catch { Write-Host '[RALAT] Gagal nyahaktifkan akaun.' -ForegroundColor Red }"
    pause
    goto ACCOUNT_TOGGLE
)
if "%tchoice%"=="2" (
    echo.
    set /p uname="Masukkan sAMAccountName yang hendak DI-ENABLE: "
    powershell -Command "try { Enable-ADAccount -Identity '%uname%'; Write-Host '[SUKSES] Akaun telah di-Enable semula!' -ForegroundColor Green } catch { Write-Host '[RALAT] Gagal aktifkan akaun.' -ForegroundColor Red }"
    pause
    goto ACCOUNT_TOGGLE
)
if "%tchoice%"=="3" goto MENU
goto ACCOUNT_TOGGLE

:INSTALL_RSAT
cls
echo ---------------------------------------------------
echo       SEMAK / PASANG MODUL RSAT ACTIVE DIRECTORY
echo ---------------------------------------------------
echo.
echo Sedang menyemak status modul RSAT pada komputer anda...
echo.
powershell -Command "if ((Get-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools*).State -eq 'Installed') { Write-Host '[INFO] Modul RSAT Active Directory SUDAH DIPASANG pada komputer ini.' -ForegroundColor Green } else { Write-Host '[INFO] Modul RSAT BELUM DIPASANG. Memulakan proses pemasangan...' -ForegroundColor Yellow; Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0; Write-Host '[SUKSES] Pemasangan RSAT Selesai!' -ForegroundColor Green }"
echo ---------------------------------------------------
echo.
pause
goto MENU
