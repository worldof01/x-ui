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
    echo -e "${BPURPLE}                     ::: xui sla tool :::${NC}"
    echo ""
}

show_menu() {
    clear
    print_logo
    
    echo -e "   ${BG_PURPLE} ${BWHITE} MAIN MENU ${NC}"
    echo -e "${BCYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BCYAN}║${NC}  ${BPURPLE}[0]${NC} ${BGREEN}➤${NC} ${BWHITE}Set SLA (Update Users)${NC}                      ${BCYAN}║${NC}"
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
    echo -e "${BPURPLE}➜${NC} Days SLA ${BYELLOW}(Default: 1)${NC}:"
    read -p "   └─ " INPUT_DAYS
    INPUT_DAYS=${INPUT_DAYS:-1}

    echo -e "${BPURPLE}➜${NC} Traffic SLA ${BYELLOW}(Default: 0)${NC}:"
    read -p "   └─ " INPUT_TRAFFIC
    INPUT_TRAFFIC=${INPUT_TRAFFIC:-0}

    echo -e "${BPURPLE}➜${NC} User Filter ${BYELLOW}(Default: ALL Users)${NC}:"
    read -p "   └─ " INPUT_FILTER
    
    echo ""
    if [ -z "$INPUT_FILTER" ]; then
        echo -e "${BG_PURPLE} STATUS ${NC} ${BWHITE}Targeting ALL users...${NC}"
    else
        echo -e "${BG_PURPLE} STATUS ${NC} ${BWHITE}Filtering for users containing: ${BYELLOW}'$INPUT_FILTER'${NC}"
    fi

    echo -e "${BCYAN}--------------------------------------------------${NC}"
    echo -e "${BYELLOW}⚡ Processing Database... Please wait.${NC}"

    export DB_PATH LOG_FILE INPUT_DAYS INPUT_TRAFFIC INPUT_FILTER

    # ==========================================
    # PYTHON LOGIC
    # ==========================================
    python3 << 'EOF'
import sqlite3
import json
import os
import time
import datetime

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

# --- Vars (SAFE GET) ---
db_path = os.environ.get('DB_PATH')
log_file = os.environ.get('LOG_FILE')

# Fix for NoneType error: Provide default empty string if None
days_input = os.environ.get('INPUT_DAYS', '1').strip()
traffic_input = os.environ.get('INPUT_TRAFFIC', '0').strip()
user_filter = os.environ.get('INPUT_FILTER', '').strip()

# Parse Traffic
is_traffic_percent = False
traffic_val = 0.0
if traffic_input.endswith('%'):
    is_traffic_percent = True
    try: traffic_val = float(traffic_input[:-1])
    except: traffic_val = 0.0
else:
    try: traffic_val = float(traffic_input)
    except: traffic_val = 0.0

# Parse Days
is_days_percent = False
days_val = 0.0
if days_input.endswith('%'):
    is_days_percent = True
    try: days_val = float(days_input[:-1])
    except: days_val = 0.0
else:
    try: days_val = float(days_input)
    except: days_val = 1.0

try:
    if not os.path.exists(db_path):
        print(f"{C.RED}❌ Error: Database not found at {db_path}{C.NC}")
        exit(1)

    con = sqlite3.connect(db_path)
    cur = con.cursor()
    rows = cur.execute("SELECT id, settings FROM inbounds").fetchall()
    updated_users_log = []
    
    for row in rows:
        inbound_id = row[0]
        try: settings = json.loads(row[1])
        except: continue 
        if 'clients' not in settings: continue
            
        clients = settings['clients']
        modified_inbound = False
        
        for client in clients:
            email = client.get('email', '')
            if user_filter and (user_filter.lower() not in email.lower()):
                continue
                
            old_traffic = client.get('totalGB', 0)
            old_expiry = client.get('expiryTime', 0)
            
            # Update Traffic
            new_traffic = old_traffic
            if traffic_val != 0:
                if is_traffic_percent:
                    change = (old_traffic * traffic_val) / 100
                    new_traffic = old_traffic + change
                else:
                    new_traffic = old_traffic + (traffic_val * 1024**3)
            client['totalGB'] = int(new_traffic)
            
            # Update Date
            current_time_ms = int(time.time() * 1000)
            new_expiry = old_expiry
            if days_val != 0:
                if old_expiry == 0:
                     if not is_days_percent:
                         new_expiry = current_time_ms + (days_val * 86400000)
                else:
                    if is_days_percent:
                        duration = old_expiry - current_time_ms
                        if duration > 0: new_expiry = old_expiry + ((duration * days_val) / 100)
                    else:
                        new_expiry = old_expiry + (days_val * 86400000)
            client['expiryTime'] = int(new_expiry)
            modified_inbound = True
            
            updated_users_log.append({
                'email': email,
                'o_tf': round(old_traffic / (1024**3), 2),
                'n_tf': round(client['totalGB'] / (1024**3), 2),
                'o_date_j': timestamp_to_jalali(old_expiry),
                'n_date_j': timestamp_to_jalali(client['expiryTime']),
                'o_date_g': timestamp_to_str(old_expiry),
                'n_date_g': timestamp_to_str(client['expiryTime'])
            })

        if modified_inbound:
            cur.execute("UPDATE inbounds SET settings = ? WHERE id = ?", (json.dumps(settings, separators=(',', ':')), inbound_id))
    
    con.commit()
    con.close()

    if not updated_users_log:
        print(f"\n{C.RED}🚫 No users found matching '{user_filter}'.{C.NC}")
    else:
        # File Report
        with open(log_file, 'w', encoding='utf-8') as f:
            idx = 1
            for u in updated_users_log:
                f.write(f"{idx:03d} | {u['email']:<20} | ✅ | {u['o_tf']}G->{u['n_tf']}G | {u['o_date_j']}->{u['n_date_j']} | {u['o_date_g']}->{u['n_date_g']}\n")
                idx += 1
        
        # Terminal Report - STRICT ALIGNMENT
        print(f"\n{C.GREEN}✔ Update Successful!{C.NC}\n")
        
        # --- FIXED COLUMN WIDTHS (INCREASED) ---
        W_ID = 4
        W_EMAIL = 16 
        W_STAT = 8
        W_TRAF = 25  # Wide enough for traffic
        W_DATE = 35  # Wide enough for dates

        # Print Header
        print(f"{C.BOX}┌{'─'*W_ID}┬{'─'*W_EMAIL}┬{'─'*W_STAT}┬{'─'*W_TRAF}┬{'─'*W_DATE}┐{C.NC}")
        print(f"{C.BOX}│{C.NC} {C.WHITE}{'ID':<{W_ID-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'User Email':<{W_EMAIL-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Status':<{W_STAT-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Traffic(GB)':<{W_TRAF-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Expiry (Jalali)':<{W_DATE-2}}{C.NC} {C.BOX}│{C.NC}")
        print(f"{C.BOX}├{'─'*W_ID}┼{'─'*W_EMAIL}┼{'─'*W_STAT}┼{'─'*W_TRAF}┼{'─'*W_DATE}┤{C.NC}")
        
        idx = 1
        for u in updated_users_log:
            # Prepare Colors
            tf_color = C.YELLOW if u['n_tf'] > u['o_tf'] else C.CYAN
            
            # --- TRUNCATE EMAIL LOGIC ---
            email_full = u['email']
            if len(email_full) > 14:
                email_display = email_full[:13] + "."
            else:
                email_display = email_full

            # --- Traffic Column Formatting ---
            tf_raw = f"{u['o_tf']}→{u['n_tf']}"
            
            # Padding: Width - 3 (margin+indent) - length
            pad_len_tf = W_TRAF - 3 - len(tf_raw)
            if pad_len_tf < 0: pad_len_tf = 0
            
            tf_str = f" {C.RED}{u['o_tf']}{C.NC}→{tf_color}{u['n_tf']}{C.NC}" + (" " * pad_len_tf)

            # --- Date Column Formatting ---
            date_raw = f"{u['o_date_j']}→{u['n_date_j']}"
            
            # Padding: Width - 3 (margin+indent) - length
            pad_len_date = W_DATE - 3 - len(date_raw)
            if pad_len_date < 0: pad_len_date = 0
            
            date_str = f" {u['o_date_j']}→{C.GREEN}{u['n_date_j']}{C.NC}" + (" " * pad_len_date)

            print(f"{C.BOX}│{C.NC} {idx:02d} {C.BOX}│{C.NC} {C.WHITE}{email_display:<{W_EMAIL-2}}{C.NC} {C.BOX}│{C.NC}   ✅   {C.BOX}│{C.NC} {tf_str} {C.BOX}│{C.NC} {date_str} {C.BOX}│{C.NC}")
            idx += 1
            
        print(f"{C.BOX}└{'─'*W_ID}┴{'─'*W_EMAIL}┴{'─'*W_STAT}┴{'─'*W_TRAF}┴{'─'*W_DATE}┘{C.NC}")
        print(f"\n{C.YELLOW}📄 Log saved to: {C.WHITE}{log_file}{C.NC}")

except Exception as e:
    print(f"{C.RED}🔥 CRITICAL ERROR: {str(e)}{C.NC}")
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
            # Width calculation: Borders + 52 internal chars
            echo -e "${BCYAN}╔════════════════════════════════════════════════════╗${NC}"
            echo -e "${BCYAN}║${NC}                    ${BPURPLE}ABOUT SCRIPT${NC}                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}╠════════════════════════════════════════════════════╣${NC}"
            # Text lines must pad to 52 chars total visible length
            echo -e "${BCYAN}║${NC} ${BWHITE}This tool manages X-UI SLAs via SQLite.${NC}            ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}Code by: ${BGREEN}worldof01${NC}                                 ${BCYAN}║${NC}"            
            echo -e "${BCYAN}║${NC} ${BWHITE}GitHub : ${BLUE}https://github.com/worldof01${NC}              ${BCYAN}║${NC}"
            echo -e "${BCYAN}╠════════════════════════════════════════════════════╣${NC}"
            echo -e "${BCYAN}║${NC}                    ${BYELLOW}DONATE (TON)${NC}                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}Buy me a coffee if you liked it!${NC}                   ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}                                                    ${BCYAN}║${NC}"
            
            # QR Code Centering Logic:
            # Box width = 52. QR width = 30. Padding = (52-30)/2 = 11 spaces.
            PAD="           "
            
            echo -e "${BCYAN}║${NC}${PAD}${BBLACK}${BG_WHITE}  ▄▄▄▄▄▄▄  ▄   ▄▄▄▄  ▄▄▄▄▄▄▄  ${NC}${PAD}${BCYAN}║${NC}"
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
            # Wallet Address Centering:
            # Box width = 52. Address = 48. Padding = (52-48)/2 = 2 spaces.
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
