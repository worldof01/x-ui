#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
DB_PATH="/etc/x-ui/x-ui.db"
LOG_FILE="sla_update_report.txt"

# ==========================================
# COLORS & STYLES
# ==========================================
# Regular Colors
BLACK='\033[0;30m'  RED='\033[0;31m'    GREEN='\033[0;32m'
YELLOW='\033[0;33m' BLUE='\033[0;34m'   PURPLE='\033[0;35m'
CYAN='\033[0;36m'   WHITE='\033[0;37m'

# Bold Colors
BBLACK='\033[1;30m' BRED='\033[1;31m'   BGREEN='\033[1;32m'
BYELLOW='\033[1;33m' BBLUE='\033[1;34m'  BPURPLE='\033[1;35m'
BCYAN='\033[1;36m'  BWHITE='\033[1;37m'

# Backgrounds
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'

# Reset
NC='\033[0m'

clear

# ==========================================
# UI FUNCTIONS
# ==========================================

print_logo() {
    echo -e "${BCYAN}"
    echo " __          __        _     _     ___   __     ___    __ "
    echo " \ \        / /       | |   | |   / _ \ / _|   / _ \  /_ |"
    echo "  \ \  /\  / /__  _ __| | __| |  | | | | |_   | | | |  | |"
    echo "   \ \/  \/ / _ \| '__| |/ _\` |  | | | |  _|  | | | |  | |"
    echo "    \  /\  / (_) | |  | | (_| |  | |_| | |    | |_| |  | |"
    echo "     \/  \/ \___/|_|  |_|\__,_|   \___/|_|     \___/   |_|"
    echo -e "${BPURPLE}                    ::: xui sla tool :::${NC}"
    echo ""
}

show_menu() {
    clear
    print_logo
    
    echo -e "   ${BG_PURPLE} ${BWHITE} MAIN MENU ${NC}"
    echo -e "${BCYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BCYAN}║${NC}  ${BPURPLE}[0]${NC} ${BGREEN}➤${NC} ${BWHITE}Set SLA (Update Users/Inbounds)${NC}              ${BCYAN}║${NC}"
    echo -e "${BCYAN}║${NC}  ${BPURPLE}[1]${NC} ${BGREEN}➤${NC} ${BWHITE}About Script${NC}                                ${BCYAN}║${NC}"
    echo -e "${BCYAN}║${NC}  ${BPURPLE}[2]${NC} ${BGREEN}➤${NC} ${BRED}Exit${NC}                                        ${BCYAN}║${NC}"
    echo -e "${BCYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}


run_update() {
    echo ""
    echo -e "${BCYAN}┌── ${BYELLOW}💡 GUIDE${BCYAN} ──────────────────────────────────────┐${NC}"
    echo -e "${BCYAN}│${NC}  ${BWHITE}Fixed Number${NC} :  ${BGREEN}10${NC}   (Adds 10 GB or Days)       ${BCYAN}│${NC}"
    echo -e "${BCYAN}│${NC}  ${BWHITE}Percentage${NC}   :  ${BGREEN}10%${NC}  (Adds 10% of current)      ${BCYAN}│${NC}"
    echo -e "${BCYAN}│${NC}  ${BWHITE}You can decrease value like ${NC}   :  ${BGREEN}-10%${NC} or ${BGREEN}-10${NC}   ${BCYAN}│${NC}"
    echo -e "${BCYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""

    # Inputs with custom styling
    echo -e "${BPURPLE}➜${NC} Target ${BYELLOW}(users/inbounds/all) [Default: all]${NC}:"
    read -p "   └─ " INPUT_TARGET
    INPUT_TARGET=${INPUT_TARGET:-all}

    echo -e "${BPURPLE}➜${NC} Days SLA ${BYELLOW}(Default: 1)${NC}:"
    read -p "   └─ " INPUT_DAYS
    INPUT_DAYS=${INPUT_DAYS:-1}

    echo -e "${BPURPLE}➜${NC} Traffic SLA ${BYELLOW}(Default: 0)${NC}:"
    read -p "   └─ " INPUT_TRAFFIC
    INPUT_TRAFFIC=${INPUT_TRAFFIC:-0}

    echo -e "${BPURPLE}➜${NC} Filter (Name/Remark) ${BYELLOW}(Default: ALL)${NC}:"
    read -p "   └─ " INPUT_FILTER
    
    echo ""
    if [ -z "$INPUT_FILTER" ]; then
        echo -e "${BG_PURPLE} STATUS ${NC} ${BWHITE}Targeting ALL matching '$INPUT_TARGET'...${NC}"
    else
        echo -e "${BG_PURPLE} STATUS ${NC} ${BWHITE}Filtering for '$INPUT_TARGET' containing: ${BYELLOW}'$INPUT_FILTER'${NC}"
    fi

    # ==========================================
    # BACKUP SYSTEM
    # ==========================================
    echo -e "${BCYAN}--------------------------------------------------${NC}"
    echo -e "${BYELLOW}📂 Backup System Initiated...${NC}"
    
    # 1. Define Backup Path
    BACKUP_ROOT="bkup"
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    # 2. Check if DB exists
    if [ -f "$DB_PATH" ]; then
        # 3. Create Directory (mkdir -p creates parent bkup if missing)
        mkdir -p "$BACKUP_DIR"
        
        # 4. Copy File
        cp "$DB_PATH" "$BACKUP_DIR/x-ui.db"
        
        if [ $? -eq 0 ]; then
             echo -e "${GREEN}✔ Backup created successfully at:${NC}"
             echo -e "  ${WHITE}➜ $BACKUP_DIR/x-ui.db${NC}"
        else
             echo -e "${RED}❌ Backup Failed! Permission denied or disk full.${NC}"
             read -p "Press Enter to continue without backup or Ctrl+C to cancel..."
        fi
    else
        echo -e "${RED}⚠ Warning: Database file not found at $DB_PATH${NC}"
        echo -e "${RED}⚠ Skipping backup.${NC}"
    fi

    echo -e "${BCYAN}--------------------------------------------------${NC}"
    echo -e "${BYELLOW}⚡ Processing Database... Please wait.${NC}"

    export DB_PATH LOG_FILE INPUT_DAYS INPUT_TRAFFIC INPUT_FILTER INPUT_TARGET

    # ==========================================
    # PYTHON LOGIC
    # ==========================================
    python3 << 'EOF'
import sqlite3
import json
import os
import time
import datetime
import traceback

# --- Python Colors ---
class C:
    CYAN = '\033[1;36m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[1;31m'
    PURPLE = '\033[1;35m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'
    BOX = '\033[0;36m'
    # FIXED: Added missing background and bold colors
    BG_PURPLE = '\033[45m'
    BWHITE = '\033[1;37m'

# --- HELPERS ---
def gregorian_to_jalali(gy, gm, gd):
    g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    if (gy > 1600):
        jy = 979
        gy -= 1600
    else:
        jy = 0
        gy -= 621
    gy2 = (gm > 2) and (gy + 1) or gy
    days = (365 * gy) + (int((gy2 + 3) / 4)) - (int((gy2 + 99) / 100)) + (int((gy2 + 399) / 400)) - 80 + gd + g_d_m[gm - 1]
    jy += 33 * (int(days / 12053))
    days %= 12053
    jy += 4 * (int(days / 1461))
    days %= 1461
    if (days > 365):
        jy += int((days - 1) / 365)
        days = (days - 1) % 365
    jm = (days < 186) and 1 + int(days / 31) or 7 + int((days - 186) / 30)
    jd = 1 + ((days < 186) and (days % 31) or ((days - 186) % 30))
    return f"{jy:04d}/{jm:02d}/{jd:02d}"

def timestamp_to_str(ts):
    if ts <= 0: return "Unlimited"
    dt = datetime.datetime.fromtimestamp(ts / 1000)
    return dt.strftime('%Y/%m/%d')

def timestamp_to_jalali(ts):
    if ts <= 0: return "Unlimited"
    dt = datetime.datetime.fromtimestamp(ts / 1000)
    return gregorian_to_jalali(dt.year, dt.month, dt.day)

def calc_new_values(old_traffic, old_expiry, traffic_val, is_traffic_percent, days_val, is_days_percent):
    # Traffic Logic
    new_traffic = old_traffic
    if traffic_val != 0:
        if is_traffic_percent:
            change = (old_traffic * traffic_val) / 100
            new_traffic = old_traffic + change
        else:
            new_traffic = old_traffic + (traffic_val * 1024**3)
    
    # Date Logic
    current_time_ms = int(time.time() * 1000)
    new_expiry = old_expiry
    was_unlimited = False

    if days_val != 0:
        if old_expiry == 0:
            new_expiry = 0
            was_unlimited = True
        else:
            if is_days_percent:
                duration = old_expiry - current_time_ms
                if duration > 0: new_expiry = old_expiry + ((duration * days_val) / 100)
            else:
                new_expiry = old_expiry + (days_val * 86400000)
    else:
        # If no days added, preserve unlimited status for reporting
        if old_expiry == 0: was_unlimited = True

    return int(new_traffic), int(new_expiry), was_unlimited

# --- MAIN LOGIC ---
db_path = os.environ.get('DB_PATH')
log_file = os.environ.get('LOG_FILE')

target_input = os.environ.get('INPUT_TARGET', 'all').lower().strip()
days_input = os.environ.get('INPUT_DAYS', '1').strip()
traffic_input = os.environ.get('INPUT_TRAFFIC', '0').strip()
filter_str = os.environ.get('INPUT_FILTER', '').strip().lower()

# Parse Inputs
is_traffic_percent = traffic_input.endswith('%')
traffic_val = float(traffic_input[:-1]) if is_traffic_percent else float(traffic_input)

is_days_percent = days_input.endswith('%')
days_val = float(days_input[:-1]) if is_days_percent else float(days_input)

updated_users_log = []
updated_inbounds_log = []

current_context = "Init"

try:
    if not os.path.exists(db_path):
        print(f"{C.RED}❌ Error: Database not found at {db_path}{C.NC}")
        exit(1)

    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # ==========================
    # PROCESS USERS (CLIENTS)
    # ==========================
    if target_input in ['users', 'all']:
        current_context = "Processing Users"
        rows = cur.execute("SELECT id, settings FROM inbounds").fetchall()
        
        for row in rows:
            inbound_id = row[0]
            try: settings = json.loads(row[1])
            except: continue
            
            if 'clients' not in settings: continue
            
            clients = settings['clients']
            modified = False
            
            for client in clients:
                email = client.get('email', 'NO_EMAIL')
                if filter_str and (filter_str not in email.lower()): continue
                
                # Get Old Values
                try: o_tf = float(client.get('totalGB', 0))
                except: o_tf = 0.0
                try: o_exp = float(client.get('expiryTime', 0))
                except: o_exp = 0.0

                # Calc New Values
                n_tf, n_exp, unlimited = calc_new_values(o_tf, o_exp, traffic_val, is_traffic_percent, days_val, is_days_percent)

                # Apply
                client['totalGB'] = n_tf
                client['expiryTime'] = n_exp
                modified = True
                
                updated_users_log.append({
                    'name': email,
                    'o_tf': round(o_tf / (1024**3), 2),
                    'n_tf': round(n_tf / (1024**3), 2),
                    'o_j': timestamp_to_jalali(o_exp),
                    'n_j': timestamp_to_jalali(n_exp),
                    'o_g': timestamp_to_str(o_exp),
                    'n_g': timestamp_to_str(n_exp),
                    'unlim': unlimited
                })

            if modified:
                cur.execute("UPDATE inbounds SET settings = ? WHERE id = ?", (json.dumps(settings, separators=(',', ':')), inbound_id))

    # ==========================
    # PROCESS INBOUNDS (PORTS)
    # ==========================
    if target_input in ['inbounds', 'all']:
        current_context = "Processing Inbounds"
        # Inbounds table usually has 'total' for traffic limit and 'expiry_time' for date
        rows = cur.execute("SELECT id, remark, total, expiry_time FROM inbounds").fetchall()
        
        for row in rows:
            i_id, remark, total, expiry = row
            if remark is None: remark = f"Inbound-{i_id}"
            
            if filter_str and (filter_str not in remark.lower()): continue
            
            # Get Old Values
            try: o_tf = float(total)
            except: o_tf = 0.0
            try: o_exp = float(expiry)
            except: o_exp = 0.0
            
            # Calc New Values
            n_tf, n_exp, unlimited = calc_new_values(o_tf, o_exp, traffic_val, is_traffic_percent, days_val, is_days_percent)
            
            # Update DB Directly
            cur.execute("UPDATE inbounds SET total = ?, expiry_time = ? WHERE id = ?", (int(n_tf), int(n_exp), i_id))
            
            updated_inbounds_log.append({
                'name': remark,
                'o_tf': round(o_tf / (1024**3), 2),
                'n_tf': round(n_tf / (1024**3), 2),
                'o_j': timestamp_to_jalali(o_exp),
                'n_j': timestamp_to_jalali(n_exp),
                'o_g': timestamp_to_str(o_exp),
                'n_g': timestamp_to_str(n_exp),
                'unlim': unlimited
            })

    con.commit()
    con.close()

    # ==========================
    # REPORTING FUNCTIONS
    # ==========================
    def print_table(title, data_list):
        if not data_list: return

        print(f"\n{C.BG_PURPLE} REPORT {C.NC} {C.BWHITE}{title}{C.NC}")
        W_ID = 4
        W_NAME = 16 
        W_TRAF = 25
        W_DATE = 35

        print(f"{C.BOX}┌{'─'*W_ID}┬{'─'*W_NAME}┬{'─'*W_TRAF}┬{'─'*W_DATE}┐{C.NC}")
        print(f"{C.BOX}│{C.NC} {C.WHITE}{'#':<{W_ID-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Name/Remark':<{W_NAME-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Traffic(GB)':<{W_TRAF-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Expiry (Jalali)':<{W_DATE-2}}{C.NC} {C.BOX}│{C.NC}")
        print(f"{C.BOX}├{'─'*W_ID}┼{'─'*W_NAME}┼{'─'*W_TRAF}┼{'─'*W_DATE}┤{C.NC}")

        idx = 1
        for u in data_list:
            # Colors
            tf_color = C.YELLOW if u['n_tf'] > u['o_tf'] else C.CYAN
            
            # Name Truncate
            name_full = str(u['name'])
            name_disp = (name_full[:13] + ".") if len(name_full) > 14 else name_full

            # Traffic
            # Re-calculating padding manually for perfect align:
            raw_len_tf = len(f"{u['o_tf']}→{u['n_tf']}")
            pad_tf = " " * max(0, W_TRAF - 3 - raw_len_tf)
            tf_str_final = f" {C.RED}{u['o_tf']}{C.NC}→{tf_color}{u['n_tf']}{C.NC} {pad_tf}"

            # Date
            if u['unlim']:
                msg = "skipped / unlimited time"
                pad_date = " " * max(0, W_DATE - 3 - len(msg))
                date_str = f" {C.CYAN}{msg}{C.NC} {pad_date}"
            else:
                raw_len_d = len(f"{u['o_j']}→{u['n_j']}")
                pad_date = " " * max(0, W_DATE - 3 - raw_len_d)
                date_str = f" {u['o_j']}→{C.GREEN}{u['n_j']}{C.NC} {pad_date}"

            print(f"{C.BOX}│{C.NC} {idx:02d} {C.BOX}│{C.NC} {C.WHITE}{name_disp:<{W_NAME-2}}{C.NC} {C.BOX}│{C.NC}{tf_str_final} {C.BOX}│{C.NC}{date_str} {C.BOX}│{C.NC}")
            idx += 1
        
        print(f"{C.BOX}└{'─'*W_ID}┴{'─'*W_NAME}┴{'─'*W_TRAF}┴{'─'*W_DATE}┘{C.NC}")

    # ==========================
    # EXECUTE REPORTS
    # ==========================
    has_updates = False
    
    if updated_users_log:
        print_table("UPDATED USERS (CLIENTS)", updated_users_log)
        has_updates = True

    if updated_inbounds_log:
        print_table("UPDATED INBOUNDS", updated_inbounds_log)
        has_updates = True
    
    if not has_updates:
        print(f"\n{C.RED}🚫 No records found matching filter '{filter_str}' in target '{target_input}'.{C.NC}")
    else:
        # File Report (Simple Append)
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write(f"--- REPORT {datetime.datetime.now()} ---\n")
            for u in updated_users_log:
                d_s = "Unlimited/Skipped" if u['unlim'] else f"{u['o_j']}->{u['n_j']}"
                f.write(f"USER | {u['name']} | {u['o_tf']}G->{u['n_tf']}G | {d_s}\n")
            for i in updated_inbounds_log:
                d_s = "Unlimited/Skipped" if i['unlim'] else f"{i['o_j']}->{i['n_j']}"
                f.write(f"INBOUND | {i['name']} | {i['o_tf']}G->{i['n_tf']}G | {d_s}\n")
                
        print(f"\n{C.GREEN}✔ Update Successful!{C.NC}")
        print(f"\n{C.PURPLE}🔄 Restarting X-UI Panel...{C.NC}")
        os.system("x-ui restart")
        print(f"\n{C.YELLOW}📄 Log saved to: {C.WHITE}{log_file}{C.NC}")

except Exception as e:
    print(f"\n{C.RED}🔥 CRITICAL ERROR!{C.NC}")
    print(f"{C.YELLOW}▶ Context: {C.WHITE}{current_context}{C.NC}")
    print(f"{C.RED}▶ Error: {C.WHITE}{str(e)}{C.NC}")
    traceback.print_exc()
EOF
}

# ==========================================
# MAIN LOOP
# ==========================================
while true; do
    show_menu
    echo -e "${BCYAN}Choose an option:${NC}"
    read -p " ➤ " choice
    case $choice in
        0)
            run_update
            echo ""
            read -p "Press Enter to return..."
            ;;
        1)
            clear
            print_logo
            echo -e "${BCYAN}╔════════════════════════════════════════════════════╗${NC}"
            echo -e "${BCYAN}║${NC}                    ${BPURPLE}ABOUT SCRIPT${NC}                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}╠════════════════════════════════════════════════════╣${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}This tool manages X-UI SLAs via SQLite.${NC}            ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}Code by: ${BGREEN}worldof01${NC}                                ${BCYAN}║${NC}"            
            echo -e "${BCYAN}║${NC} ${BWHITE}GitHub : ${BLUE}https://github.com/worldof01${NC}              ${BCYAN}║${NC}"
            echo -e "${BCYAN}╠════════════════════════════════════════════════════╣${NC}"
            echo -e "${BCYAN}║${NC}                    ${BYELLOW}DONATE (TON)${NC}                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}Buy me a coffee if you liked it!${NC}                   ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}                                                    ${BCYAN}║${NC}"
            PAD="           "
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  ▄▄▄▄▄▄▄  ▄   ▄▄▄ ▄▄▄▄▄▄▄    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █ ▄▄▄ █ ▀ ▀█▄▀██ █ ▄▄▄ █    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █ ███ █ ▀█▀ ▄▀ █ █ ███ █    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █▄▄▄▄▄█ █ █ █▀▄█ █▄▄▄▄▄█    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  ▄▄▄▄  ▄ ▄▄▄▄▀ ▄▄   ▄ ▄ ▄    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █▀▄▀▀ ▄▀█▀▀▀▀█▀▄▀▄▀▄█▀ █    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █ █▀▀▄▄  █▀▀ ▀▄█ █▄ █ ▀█    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  ▄▄▄▄▄▄▄ █▄▄ ▀▄▀█ ▄ █ ▀▀█    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █ ▄▄▄ █ ▄ █▄█ ▄█▄▄▄█ █▄█    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  █ ███ █ █▀▄▀ ▀▄▀ █▄▀█▀▄█    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  ▀▀▀▀▀▀▀ ▀   ▀  ▀   ▀   ▀    ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}                                                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}  ${GREEN}UQAykVgirxEyv8cgHAgpPGXwzUYFwviRZWS1QMGwx3KDHrsV${NC}  ${BCYAN}║${NC}"
            echo -e "${BCYAN}╚════════════════════════════════════════════════════╝${NC}"
            echo ""
            read -p "Press Enter to return..."
            ;;
        2)
            echo -e "${BRED}good bye...${NC}"
            exit 0
            ;;
        *)
            echo -e "${BRED}Invalid option!${NC}"
            sleep 1
            ;;
    esac
done
