#!/bin/ash
# Installation script by ARYO.
# Versi mandiri (self-contained) yang tidak memerlukan koneksi internet untuk instalasi.
# Semua file yang dibutuhkan sudah disematkan di dalam skrip ini.
# Token bot default ditambahkan.

# --- Definisi Variabel Direktori ---
CRON_JOB='0 0 * * * truncate -s 0 /tmp/known_mac.txt && > /tmp/dhcp.leases && /etc/init.d/dnsmasq restart'
DIR=/usr/bin
CONF=/etc/config
ETC=/etc/hotplug.d/dhcp
MODEL=/usr/lib/lua/luci/model/cbi
CON=/usr/lib/lua/luci/controller

# --- Fungsi untuk Membuat File dari Konten yang Disematkan ---

# 1. Membuat file /usr/lib/lua/luci/model/cbi/telegram_config.lua
create_telegram_config_lua() {
    cat <<'EOF' > "$MODEL/telegram_config.lua"
m = Map("telegram", translate("Notifikasi Telegram"), translate("Pengaturan Notifikasi Telegram untuk memantau pengguna Hotspot."))

s = m:section(TypedSection, "telegram", "")
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Aktifkan Notif Telegram"))

tkn = s:option(Value, "token", translate("TOKEN BOT"), translate("Dapatkan token dari @BotFather di Telegram."))
tkn.password = true

s:option(Value, "chat_id", translate("CHAT ID"), translate("Dapatkan ID Obrolan Anda dari @userinfobot di Telegram."))

s:option(Value, "hostname", translate("Hostname"), translate("Nama host perangkat ini, digunakan dalam pesan notifikasi."))

s:option(Value, "text_login", translate("Pesan Teks Login"), translate("Pesan teks yang akan dikirim saat pengguna login."))

s:option(Value, "text_logout", translate("Pesan Teks Logout"), translate("Pesan teks yang akan dikirim saat pengguna logout."))

s:option(Value, "text_failed", translate("Pesan Teks Gagal"), translate("Pesan teks yang akan dikirim saat pengguna gagal login."))

s:option(Value, "text_mikrotik", translate("Pesan Teks Kirim ke Mikrotik"), translate("Pesan teks yang akan dikirim ke Mikrotik saat pengguna login."))

return m
EOF
    echo "File $MODEL/telegram_config.lua berhasil dibuat."
}

# 2. Membuat file /usr/bin/telegram
create_telegram_executable() {
    cat <<'EOF' > "$DIR/telegram"
#!/bin/sh
# Telegram.sh - By: @Hvl233
# Modded by SRPCOM

# Baca Konfigurasi dari /etc/config/telegram
config_load telegram
config_get enabled telegram enabled
config_get token telegram token
config_get chat_id telegram chat_id
config_get hostname telegram hostname

# Periksa apakah Notifikasi Telegram diaktifkan
if [ "$enabled" != "1" ]; then
    exit 0
fi

send_message() {
    local text="$1"
    local url="https://api.telegram.org/bot${token}/sendMessage"
    
    # Kirim pesan menggunakan curl
    # Menambahkan --insecure untuk mengabaikan verifikasi SSL jika diperlukan, 
    # namun sebaiknya sertifikat diurus dengan benar.
    # Menambahkan timeout untuk mencegah skrip menggantung terlalu lama.
    curl -s --connect-timeout 10 --max-time 15 -d "chat_id=${chat_id}&text=${text}&parse_mode=Markdown" "$url" >/dev/null
}

# Ambil Argumen
action="$1"
user="$2"
mac="$3"

# Buat Pesan Berdasarkan Tindakan
case "$action" in
    "login")
        message="🟢 *Login Berhasil*
        User: \`$user\`
        MAC: \`$mac\`
        Hostname: \`$hostname\`"
        ;;
    "logout")
        message="🔴 *Logout*
        User: \`$user\`
        MAC: \`$mac\`
        Hostname: \`$hostname\`"
        ;;
    "failed")
        message="⚠️ *Login Gagal*
        User: \`$user\`
        MAC: \`$mac\`
        Hostname: \`$hostname\`"
        ;;
    *)
        # Jika tidak ada tindakan yang cocok, kirim teks mentah
        # Pastikan untuk melakukan sanitasi jika input berasal dari sumber yang tidak terpercaya
        message="$*"
        ;;
esac

# Kirim Pesan
send_message "$message"
EOF
    echo "File $DIR/telegram berhasil dibuat."
}

# 3. Membuat file /usr/bin/unmonfi
create_unmonfi_script() {
    cat <<'EOF' > "$DIR/unmonfi"
#!/bin/ash
# Uninstall script by ARYO.
clear
echo "Memulai proses uninstallasi..."

# Hapus file-file yang telah diinstal
echo "Menghapus file..."
rm -f /usr/bin/telegram
rm -f /usr/lib/lua/luci/model/cbi/telegram_config.lua
rm -f /usr/lib/lua/luci/controller/telegram.lua
rm -f /etc/config/telegram
rm -f /etc/hotplug.d/dhcp/99-device-detector
rm -f /tmp/known_mac.txt
rm -f /tmp/dhcp.leases
rm -f /usr/bin/unmonfi

# Hapus Cron job
echo "Menghapus cron job..."
# Pastikan hanya menghapus cron job yang spesifik
if crontab -l 2>/dev/null | grep -Fq 'truncate -s 0 /tmp/known_mac.txt && > /tmp/dhcp.leases && /etc/init.d/dnsmasq restart'; then
    crontab -l 2>/dev/null | grep -Fv 'truncate -s 0 /tmp/known_mac.txt && > /tmp/dhcp.leases && /etc/init.d/dnsmasq restart' | crontab -
    echo "Cron job berhasil dihapus."
else
    echo "Cron job tidak ditemukan."
fi

echo "Membersihkan cache LuCI..."
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*

clear
echo "Proses uninstallasi selesai."
echo "Silakan reboot perangkat Anda untuk memastikan semua perubahan diterapkan."
echo "Terima kasih telah menggunakan skrip dari SRPCOM."
EOF
    echo "File $DIR/unmonfi berhasil dibuat."
}

# 4. Membuat file /etc/config/telegram
create_telegram_conf_file() {
    cat <<EOF > "$CONF/telegram"
config telegram
	option enabled '1'
	option token '7860070531:AAH7_VWvMMlifAmhF9k6EJ5CLZ1WuGezI6M' # Token default diisi di sini
	option chat_id 'GANTI_DENGAN_CHAT_ID_ANDA'
	option hostname 'OpenWrt-SRPCOM'
	option text_login 'User {user} login dari {mac}'
	option text_logout 'User {user} logout'
	option text_failed 'User {user} gagal login'
	option text_mikrotik '/ip hotspot active remove [find user="{user}"]'
EOF
    echo "File $CONF/telegram berhasil dibuat dengan token default."
}

# 5. Membuat file /usr/lib/lua/luci/controller/telegram.lua
create_luci_controller() {
    cat <<'EOF' > "$CON/telegram.lua"
module("luci.controller.telegram", package.seeall)

function index()
    entry({"admin", "services", "telegram"}, cbi("telegram_config"), "Telegram", 99).dependent = false
end
EOF
    echo "File $CON/telegram.lua berhasil dibuat."
}

# 6. Membuat file /etc/hotplug.d/dhcp/99-device-detector
create_device_detector() {
    cat <<'EOF' > "$ETC/99-device-detector"
#!/bin/ash

# Skrip ini mendeteksi perangkat baru yang terhubung ke jaringan
# dan mengirim notifikasi melalui Telegram.

# Aksi yang diberikan oleh hotplug (misalnya, 'add', 'remove')
ACTION=$1
# Alamat MAC perangkat
MAC=$2
# Alamat IP yang diberikan
IP=$3
# Nama host perangkat (jika tersedia)
HOSTNAME=$4

# File untuk menyimpan daftar MAC yang sudah dikenal
KNOWN_MACS_FILE="/tmp/known_mac.txt"

# Hanya berjalan untuk aksi 'add' atau 'update' dari dnsmasq
if [ "$ACTION" = "add" ] || [ "$ACTION" = "update" ]; then
    # Periksa apakah file daftar MAC ada, jika tidak, buat file tersebut
    [ -f "$KNOWN_MACS_FILE" ] || touch "$KNOWN_MACS_FILE"

    # Periksa apakah MAC sudah ada di dalam file
    if ! grep -qFx "$MAC" "$KNOWN_MACS_FILE"; then # -x untuk pencocokan baris penuh, -F untuk string literal
        # Jika MAC belum ada, ini adalah perangkat baru
        
        # Buat pesan notifikasi
        # Menggunakan printf untuk keamanan dan fleksibilitas yang lebih baik dalam memformat string
        MESSAGE_HOSTNAME=${HOSTNAME:-N/A} # Default ke N/A jika HOSTNAME kosong
        MESSAGE=$(printf "✅ *Perangkat Baru Terhubung*\n--------------------------------------\n➤ *Hostname:* \`%s\`\n➤ *Alamat IP:* \`%s\`\n➤ *Alamat MAC:* \`%s\`\n--------------------------------------\nPowered by: *SRPCOM*" "$MESSAGE_HOSTNAME" "$IP" "$MAC")

        # Kirim notifikasi menggunakan skrip telegram
        # Pastikan skrip telegram dapat diakses dan dieksekusi
        if [ -x "/usr/bin/telegram" ]; then
            /usr/bin/telegram "$MESSAGE"
        else
            logger -t device-detector "Error: Skrip /usr/bin/telegram tidak ditemukan atau tidak dapat dieksekusi."
        fi

        # Tambahkan MAC baru ke dalam daftar yang sudah dikenal
        echo "$MAC" >> "$KNOWN_MACS_FILE"
    fi
fi
EOF
    echo "File $ETC/99-device-detector berhasil dibuat."
}


# --- Fungsi Instalasi Utama ---

install_components() {
    echo "Memulai instalasi komponen..."
    
    # Membuat direktori jika belum ada (khususnya untuk hotplug.d)
    mkdir -p "$DIR" "$CONF" "$ETC" "$MODEL" "$CON"

    # Membuat semua file yang diperlukan
    create_telegram_config_lua
    create_telegram_executable
    create_unmonfi_script
    create_telegram_conf_file
    create_luci_controller
    create_device_detector
    
    # Memberikan hak eksekusi pada skrip yang relevan
    echo "Memberikan hak eksekusi..."
    chmod +x "$DIR/telegram"
    chmod +x "$DIR/unmonfi"
    # chmod +x "$CON/telegram.lua" # File Lua biasanya tidak memerlukan bit eksekusi
    chmod +x "$ETC/99-device-detector"
    
    echo "Semua komponen berhasil dibuat dan dikonfigurasi."
}

finish() {
    clear
    echo "✅ Menambahkan Cronjob untuk reset harian."
    # Cek apakah baris sudah ada di crontab untuk menghindari duplikasi
    if ! crontab -l 2>/dev/null | grep -Fq "$CRON_JOB"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "✅ Cron job berhasil ditambahkan."
    else
        echo "ℹ️ Cron job sudah ada, tidak ditambahkan ulang."
    fi
    echo ""
    echo "============================================================"
    echo "      INSTALL SUCCESSFULLY ;) - INSTALASI BERHASIL"
    echo "============================================================"
    echo ""
    echo "LANGKAH SELANJUTNYA YANG HARUS ANDA LAKUKAN:"
    echo "1. Buka menu Layanan > Notifikasi Telegram di antarmuka LuCI."
    echo "2. Token BOT sudah terisi secara default. Anda HANYA PERLU mengisi CHAT ID Anda."
    echo "3. Sesuaikan pengaturan lain jika diperlukan."
    echo "4. Klik 'Simpan & Terapkan'."
    echo ""
    echo "Untuk menghapus instalasi ini, ketik 'unmonfi' di terminal."
    echo ""
    echo "Youtube: SRPCOM"
    echo "============================================================"
    echo ""
}

# --- Alur Eksekusi Skrip ---
clear
echo ""
echo "============================================================================================="
echo "|| Install Deteksi Monitor Wifi Openwrt - Versi Mandiri (Offline)                           ||"
echo "|| Script ini berfungsi meneruskan informasi perangkat baru yang terkoneksi di OPENWRT kita.||"
echo "|| S R P C O M                                                                               ||"
echo "============================================================================================="
echo ""
echo "Instalasi akan berjalan secara otomatis tanpa memerlukan input."
sleep 3

install_components
finish

exit 0
