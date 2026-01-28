#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
# Set to "true" to see detailed logs
DEBUG_MODE="false"
BBLUE='\033[1;34m'
DB_PATH="/etc/x-ui/x-ui.db"
LOG_FILE="manager_report.txt"
BACKUP_ROOT="bkup"

# ==========================================
# COLORS & STYLES
# ==========================================
# Regular
BLACK='\033[0;30m'  RED='\033[0;31m'    GREEN='\033[0;32m'
YELLOW='\033[0;33m' BLUE='\033[0;34m'   PURPLE='\033[0;35m'
CYAN='\033[0;36m'   WHITE='\033[0;37m'
GREY='\033[0;90m'   NC='\033[0m'

# Bold/Backgrounds
BBLACK='\033[1;30m' BRED='\033[1;31m'   BGREEN='\033[1;32m'
BYELLOW='\033[1;33m' BBLUE='\033[1;34m'  BPURPLE='\033[1;35m'
BCYAN='\033[1;36m'  BWHITE='\033[1;37m'
BG_WHITE='\033[47m' BG_PURPLE='\033[45m'
BG_GREEN='\033[42m'

clear

# ==========================================
# UI FUNCTIONS
# ==========================================
print_centered_logo() {
    MAIN_COLOR='\033[1;37m'
    SHADOW_COLOR='\033[1;30m'
    NC='\033[0m'

    read -r -d '' LOGO_TOP << "EOF"
██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗      ██████╗ ███████╗     ██████╗  ██╗
██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗    ██╔═══██╗██╔════╝    ██╔═████╗███║
██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║    ██║   ██║█████╗      ██║██╔██║╚██║
██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║    ██║   ██║██╔══╝      ████╔╝██║ ██║
╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝    ╚██████╔╝██║         ╚██████╔╝ ██║
 ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝      ╚═════╝ ╚═╝          ╚═════╝  ╚═╝
EOF

    read -r -d '' LOGO_BOTTOM << "EOF"
██╗  ██╗       ██╗   ██╗██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ 
╚██╗██╔╝       ██║   ██║██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
 ╚███╔╝█████╗  ██║   ██║██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
 ██╔██╗╚════╝  ██║   ██║██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
██╔╝ ██╗       ╚██████╔╝██║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
╚═╝  ╚═╝        ╚═════╝ ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
EOF

    width_top=88
    width_bottom=96
    padding_diff=$(( (width_bottom - width_top) / 2 ))
    padding_spaces=$(printf '%*s' "$padding_diff" "")
    term_width=$(tput cols)
    left_margin=$(( (term_width - width_bottom) / 2 ))
    [ "$left_margin" -lt 0 ] && left_margin=0
    margin_spaces=$(printf '%*s' "$left_margin" "")

    while IFS= read -r line; do
        colored_line="${SHADOW_COLOR}${line//█/${MAIN_COLOR}█${SHADOW_COLOR}}${NC}"
        echo -e "${margin_spaces}${padding_spaces}${colored_line}"
    done <<< "$LOGO_TOP"

    while IFS= read -r line; do
        colored_line="${SHADOW_COLOR}${line//█/${MAIN_COLOR}█${SHADOW_COLOR}}${NC}"
        echo -e "${margin_spaces}${colored_line}"
    done <<< "$LOGO_BOTTOM"
}

print_logo() {
    if [ "$DEBUG_MODE" == "true" ]; then
        echo -e "${BRED}            [ DEBUG MODE IS ON ]${NC}"
    fi
    echo ""
    print_centered_logo
}

show_menu() {
    clear
    print_logo
    echo -e "   ${BG_PURPLE} ${BWHITE} MAIN MENU ${NC}"
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${PURPLE}[0]${NC} ${GREEN}➤${NC} ${WHITE}User Management${NC} (SLA / Delete)              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${PURPLE}[1]${NC} ${GREEN}➤${NC} ${WHITE}About Script${NC}                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${PURPLE}[2]${NC} ${GREEN}➤${NC} ${BRED}Exit${NC}                                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_option() {
    echo -e "   ${PURPLE}[$1]${NC} ${WHITE}$2${NC} ${YELLOW}$3${NC}"
}

run_manager() {
    echo ""
    echo -e "${CYAN}┌── ${YELLOW}💡 GUIDE${CYAN} ──────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}First Select Job, Then Target, Then Filters${NC}     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}Backup is taken automatically before changes${NC}    ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""

    # --- 1. JOB ---
    echo -e "${PURPLE}➜${NC} Select Job ${YELLOW}[Default: 1]${NC}:"
    print_option "1" "Set SLA" "(Update Traffic/Expiry + Enable)"
    print_option "2" "Delete Selected" "(Remove Matching Users)"
    read -p "   └─ Selection [1-2]: " J_OPT
    J_OPT=${J_OPT:-1}
    if [ "$J_OPT" == "2" ]; then INPUT_JOB="delete"; else INPUT_JOB="sla"; fi

    # --- 2. TARGET ---
    echo -e "\n${PURPLE}➜${NC} Select Target ${YELLOW}[Default: 1]${NC}:"
    print_option "1" "All Users" "(Clients only)"
    print_option "2" "Inbounds" "(Ports/Inbounds Only)"
    read -p "   └─ Selection [1-2]: " T_OPT
    T_OPT=${T_OPT:-1}
    case $T_OPT in
        2) INPUT_TARGET="inbounds" ;;
        *) INPUT_TARGET="users" ;;
    esac

    if [ "$INPUT_TARGET" == "inbounds" ] && [ "$INPUT_JOB" == "delete" ]; then
        echo -e "\n${RED}⚠  Operation Not Allowed:${NC} You cannot batch DELETE inbounds with this script."
        echo -e "   Switched Job to ${GREEN}Set SLA${NC} automatically."
        INPUT_JOB="sla"
    fi

    # --- 3. INPUTS ---
    INPUT_DAYS="0"; INPUT_TRAFFIC="0"
    if [ "$INPUT_JOB" == "sla" ]; then
        echo -e "\n${CYAN}┌── ${YELLOW}SLA VALUES${CYAN} ──────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} Fixed: ${GREEN}10${NC} (Add) | Percent: ${GREEN}10%${NC} | Reduce: ${GREEN}-10${NC}       ${CYAN}│${NC}"
        echo -e "${CYAN}└────────────────────────────────────────────────────┘${NC}"
        echo -e "${PURPLE}➜${NC} Days SLA ${YELLOW}(Default: 0)${NC}:"
        read -p "   └─ " INPUT_DAYS
        INPUT_DAYS=${INPUT_DAYS:-0}
        echo -e "${PURPLE}➜${NC} Traffic SLA ${YELLOW}(Default: 0)${NC}:"
        read -p "   └─ " INPUT_TRAFFIC
        INPUT_TRAFFIC=${INPUT_TRAFFIC:-0}
    fi

    # --- 4. FILTERS ---
    echo -e "\n${PURPLE}➜${NC} Time Filter ${YELLOW}[Default: 1]${NC}:"
    print_option "1" "All" "(Ignore Expiry Date)"
    print_option "2" "Active" "(Not Expired)"
    print_option "3" "Expired" "(Date Passed)"
    read -p "   └─ Selection [1-3]: " TIME_OPT
    TIME_OPT=${TIME_OPT:-1}
    case $TIME_OPT in
        2) INPUT_TIME_STATUS="active" ;;
        3) INPUT_TIME_STATUS="expired" ;;
        *) INPUT_TIME_STATUS="all" ;;
    esac

    echo -e "\n${PURPLE}➜${NC} Traffic Filter ${YELLOW}[Default: 1]${NC}:"
    print_option "1" "All" "(Ignore Traffic Usage)"
    print_option "2" "Finished" "(Volume Exhausted)"
    print_option "3" "Not Finished" "(Volume Remaining)"
    read -p "   └─ Selection [1-3]: " VOL_OPT
    VOL_OPT=${VOL_OPT:-1}
    case $VOL_OPT in
        2) INPUT_VOL_STATUS="finished" ;;
        3) INPUT_VOL_STATUS="not_finished" ;;
        *) INPUT_VOL_STATUS="all" ;;
    esac

    echo -e "\n${PURPLE}➜${NC} Name Filter (Remark/Email) ${YELLOW}(Default: ALL)${NC}:"
    read -p "   └─ " INPUT_FILTER

    # --- CONFIRMATION ---
    JOB_DISPLAY="UPDATE SLA"
    if [ "$INPUT_JOB" == "delete" ]; then JOB_DISPLAY="${RED}DELETE USERS${NC}"; fi
    
    echo -e "\n${BG_PURPLE} STATUS ${NC} ${BWHITE}Job:${JOB_DISPLAY} | Target:${INPUT_TARGET} | Time:${INPUT_TIME_STATUS} | Traffic:${INPUT_VOL_STATUS} | Filter:${INPUT_FILTER}${NC}"
    
    if [ "$INPUT_JOB" == "delete" ]; then
        echo -e "${RED}⚠ WARNING: You are about to DELETE users matching these filters!${NC}"
        read -p "Press Enter to confirm or Ctrl+C to cancel..."
    fi

    # --- BACKUP ---
    echo -e "${BCYAN}--------------------------------------------------${NC}"
    echo -e "${YELLOW}📂 Backup System Initiated...${NC}"
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

    if [ -f "$DB_PATH" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$DB_PATH" "$BACKUP_DIR/x-ui.db"
        if [ $? -eq 0 ]; then
             echo -e "${GREEN}✔ Backup created: $BACKUP_DIR/x-ui.db${NC}"
        else
             echo -e "${RED}❌ Backup Failed!${NC}"
        fi
    else
        echo -e "${RED}⚠ Warning: Database file not found at $DB_PATH${NC}"
    fi

    echo -e "${BCYAN}--------------------------------------------------${NC}"
    echo -e "${YELLOW}⚡ Processing Database...${NC}"

    export DB_PATH LOG_FILE INPUT_DAYS INPUT_TRAFFIC INPUT_FILTER INPUT_TARGET INPUT_TIME_STATUS INPUT_VOL_STATUS INPUT_JOB DEBUG_MODE

    # ==========================================
    # PYTHON LOGIC
    # ==========================================
    python3 << 'EOF'
import sqlite3
import json
import os
import time
import datetime
import sys

# Flush output immediately
sys.stdout.reconfigure(line_buffering=True)

# --- Colors ---
class C:
    CYAN = '\033[1;36m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[1;31m'
    NC = '\033[0m'
    BOX = '\033[0;36m'
    WHITE = '\033[1;37m'
    GREY = '\033[0;90m'

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

def timestamp_to_jalali(ts):
    if ts <= 0: return "Unlimited"
    if ts < 100000: return f"{ts} Days (Wait)"
    dt = datetime.datetime.fromtimestamp(ts / 1000)
    return gregorian_to_jalali(dt.year, dt.month, dt.day)

def format_volume(b):
    if b <= 0: return "Unlimited"
    if b < 1024: return f"{b} B"
    if b < 1024**2: return f"{round(b/1024, 2)} KB"
    if b < 1024**3: return f"{round(b/1024**2, 2)} MB"
    return f"{round(b/1024**3, 2)} GB"

def get_visual_len(s):
    clean = s.replace(C.RED, '').replace(C.GREEN, '').replace(C.YELLOW, '').replace(C.CYAN, '').replace(C.NC, '')
    return len(clean)

# --- MAIN ---
print(f"{C.CYAN}--- PYTHON ENGINE STARTED ---{C.NC}")

db_path = os.environ.get('DB_PATH')
log_file = os.environ.get('LOG_FILE')
debug_mode = os.environ.get('DEBUG_MODE', 'false').lower() == 'true'

# Inputs
job_input = os.environ.get('INPUT_JOB', 'sla').lower().strip()
target_input = os.environ.get('INPUT_TARGET', 'users').lower().strip()
time_status_input = os.environ.get('INPUT_TIME_STATUS', 'all').lower().strip()
vol_status_input = os.environ.get('INPUT_VOL_STATUS', 'all').lower().strip()
filter_str = os.environ.get('INPUT_FILTER', '').strip().lower()

days_input = os.environ.get('INPUT_DAYS', '0').strip()
traffic_input = os.environ.get('INPUT_TRAFFIC', '0').strip()

# Values parsing
is_traffic_percent = traffic_input.endswith('%')
try: traffic_val = float(traffic_input[:-1]) if is_traffic_percent else float(traffic_input)
except: traffic_val = 0.0

is_days_percent = days_input.endswith('%')
try: days_val = float(days_input[:-1]) if is_days_percent else float(days_input)
except: days_val = 0.0

updated_log = []
current_time_ms = int(time.time() * 1000)

try:
    if not os.path.exists(db_path):
        print(f"{C.RED}❌ CRITICAL: Database file not found at {db_path}{C.NC}")
        exit(1)

    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # =========================================================
    # LOGIC 1: PROCESS INBOUNDS
    # =========================================================
    if target_input == 'inbounds':
        if debug_mode: print(f"{C.GREY}[INFO] Processing Inbounds Mode...{C.NC}")
        
        rows = cur.execute("SELECT id, up, down, total, expiry_time, remark, port, protocol FROM inbounds").fetchall()
        
        for row in rows:
            i_id = row[0]
            used_bytes = (row[1] if row[1] else 0) + (row[2] if row[2] else 0)
            o_tf = int(row[3]) if row[3] else 0
            o_exp = int(row[4]) if row[4] else 0
            remark = str(row[5]) if row[5] else ""
            port = str(row[6])
            
            inbound_name = f"{remark} ({port})".strip().lower()
            
            should_skip = False
            skip_reason = ""
            
            if filter_str and (filter_str not in inbound_name):
                should_skip = True; skip_reason = "Name Mismatch"
            if not should_skip:
                is_expired = False
                if o_exp > 100000: is_expired = (o_exp < current_time_ms)
                
                if time_status_input == 'active' and is_expired:
                    should_skip = True; skip_reason = "Expired"
                elif time_status_input == 'expired' and not is_expired:
                    should_skip = True; skip_reason = "Active"
            if not should_skip:
                if o_tf <= 0: is_finished = False
                else: is_finished = (used_bytes >= o_tf)
                if vol_status_input == 'finished' and not is_finished:
                    should_skip = True; skip_reason = "Not Finished"
                elif vol_status_input == 'not_finished' and is_finished:
                    should_skip = True; skip_reason = "Finished"

            if debug_mode:
                res = "SKIP" if should_skip else "MATCH"
                print(f"{C.GREY}[INBOUND] {inbound_name} | {res} {skip_reason}{C.NC}")

            if should_skip: continue

            # Calc
            new_tf = o_tf
            if traffic_val != 0 and o_tf > 0:
                if is_traffic_percent:
                    change = (o_tf * traffic_val) / 100
                    new_tf = int(o_tf + change)
                else:
                    new_tf = int(o_tf + (traffic_val * 1024**3))

            new_ex = o_exp
            if days_val != 0:
                # Logic: If it is a duration (small number) AND used=0, DO NOT TOUCH.
                if o_exp < 100000 and used_bytes == 0:
                    new_ex = o_exp
                else:
                    # Otherwise (Used duration, OR Timestamp) -> Extend
                    if o_exp < 100000: 
                        new_ex = int(current_time_ms + (days_val * 86400000))
                    else:
                        if is_days_percent:
                            duration = o_exp - current_time_ms
                            if duration > 0: new_ex = int(o_exp + ((duration * days_val) / 100))
                        else:
                            new_ex = int(o_exp + (days_val * 86400000))

            if new_tf != o_tf or new_ex != o_exp:
                cur.execute("UPDATE inbounds SET total = ?, expiry_time = ?, enable = 1 WHERE id = ?", (new_tf, new_ex, i_id))
                updated_log.append({
                    'name': inbound_name, 'status': 'UPDATED',
                    'o_tf': o_tf, 'n_tf': new_tf,
                    'o_ex': o_exp, 'n_ex': new_ex
                })

    # =========================================================
    # LOGIC 2: PROCESS CLIENTS
    # =========================================================
    else: 
        if debug_mode: print(f"{C.GREY}[INFO] Processing Clients Mode...{C.NC}")

        traffic_cache = {}
        try:
            t_rows = cur.execute("SELECT email, up, down FROM client_traffics").fetchall()
            for tr in t_rows:
                if tr[0]:
                    email_key = str(tr[0]).strip().lower()
                    traffic_cache[email_key] = (tr[1] if tr[1] else 0) + (tr[2] if tr[2] else 0)
        except Exception as e:
            if debug_mode: print(f"{C.RED}Error reading client_traffics: {e}{C.NC}")

        rows = cur.execute("SELECT id, settings FROM inbounds").fetchall()
        for row in rows:
            inbound_id = row[0]
            try: settings = json.loads(row[1])
            except: continue
            
            if 'clients' not in settings: continue
            clients = settings['clients']
            new_clients = []
            is_modified = False
            
            for client in clients:
                email = client.get('email', 'NO_EMAIL')
                email_key = str(email).strip().lower()
                
                raw_total = client.get('totalGB', 0)
                try: o_tf = int(float(raw_total)) 
                except: o_tf = 0
                
                raw_expiry = client.get('expiryTime', 0)
                try: o_exp = int(float(raw_expiry))
                except: o_exp = 0

                used_bytes = traffic_cache.get(email_key, 0)
                
                should_skip = False
                if filter_str and (filter_str not in email_key): should_skip = True
                if not should_skip:
                    is_expired = False
                    if o_exp > 100000: is_expired = (o_exp < current_time_ms)
                    
                    if time_status_input == 'active' and is_expired: should_skip = True
                    elif time_status_input == 'expired' and not is_expired: should_skip = True
                
                if not should_skip:
                    if o_tf <= 0: is_finished = False
                    else: is_finished = (used_bytes >= o_tf)
                    if vol_status_input == 'finished' and not is_finished: should_skip = True
                    elif vol_status_input == 'not_finished' and is_finished: should_skip = True

                if should_skip:
                    new_clients.append(client)
                    continue

                log_entry = {'name': email, 'status': 'UNKNOWN', 'o_tf': o_tf, 'o_ex': o_exp, 'n_tf': o_tf, 'n_ex': o_exp}

                if job_input == 'delete':
                    is_modified = True
                    log_entry['status'] = 'DELETED'
                    cur.execute("DELETE FROM client_traffics WHERE email = ?", (email,))
                else:
                    new_tf = o_tf
                    if traffic_val != 0 and o_tf > 0:
                        if is_traffic_percent:
                            change = (o_tf * traffic_val) / 100
                            new_tf = int(o_tf + change)
                        else:
                            new_tf = int(o_tf + (traffic_val * 1024**3))
                    
                    new_ex = o_exp
                    if days_val != 0:
                        # STRICT RULE: If it is a Duration (small number) AND NOT used, keep it.
                        if o_exp < 100000 and used_bytes == 0:
                            new_ex = o_exp
                        else:
                            # It is a timestamp OR a used duration -> EXTEND IT
                            if o_exp < 100000: 
                                new_ex = int(current_time_ms + (days_val * 86400000))
                            else:
                                if is_days_percent:
                                    duration = o_exp - current_time_ms
                                    if duration > 0: new_ex = int(o_exp + ((duration * days_val) / 100))
                                else:
                                    new_ex = int(o_exp + (days_val * 86400000))
                    
                    if new_tf != o_tf or new_ex != o_exp:
                        client['totalGB'] = new_tf
                        client['expiryTime'] = new_ex
                        client['enable'] = True
                        
                        try:
                            cur.execute("UPDATE client_traffics SET total = ?, expiry_time = ?, enable = 1 WHERE email = ?", (new_tf, new_ex, email))
                        except:
                            cur.execute("UPDATE client_traffics SET total = ?, expiry_time = ? WHERE email = ?", (new_tf, new_ex, email))
                        
                        log_entry['status'] = 'UPDATED'
                        log_entry['n_tf'] = new_tf
                        log_entry['n_ex'] = new_ex
                        is_modified = True
                    
                    new_clients.append(client)
                
                if log_entry['status'] != 'UNKNOWN':
                    updated_log.append(log_entry)

            if is_modified:
                settings['clients'] = new_clients
                new_json = json.dumps(settings, indent=2, ensure_ascii=False)
                cur.execute("UPDATE inbounds SET settings = ? WHERE id = ?", (new_json, inbound_id))

    con.commit()
    con.close()

    # --- REPORTING ---
    W_ID = 4; W_NAME = 18; W_STAT = 10; W_TRAF = 24; W_DATE = 28

    if not updated_log:
        print(f"\n{C.RED}🚫 No targets found matching criteria.{C.NC}")
    else:
        print(f"\n{C.YELLOW} REPORT {C.NC} {C.WHITE}Processed {len(updated_log)} Items{C.NC}")
        print(f"{C.BOX}┌{'─'*W_ID}┬{'─'*W_NAME}┬{'─'*W_STAT}┬{'─'*W_TRAF}┬{'─'*W_DATE}┐{C.NC}")
        print(f"{C.BOX}│{C.NC} {C.WHITE}{'#':<{W_ID-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Name':<{W_NAME-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Status':<{W_STAT-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Traffic(GB)':<{W_TRAF-2}}{C.NC} {C.BOX}│{C.NC} {C.WHITE}{'Expiry':<{W_DATE-2}}{C.NC} {C.BOX}│{C.NC}")
        print(f"{C.BOX}├{'─'*W_ID}┼{'─'*W_NAME}┼{'─'*W_STAT}┼{'─'*W_TRAF}┼{'─'*W_DATE}┤{C.NC}")

        for idx, u in enumerate(updated_log, 1):
            name = (u['name'][:15] + '..') if len(u['name']) > 16 else u['name']
            
            if u['status'] == 'DELETED':
                status = f"{C.RED}DELETED{C.NC} "
                traf = f"{C.RED}{format_volume(u['o_tf'])}{C.NC}"
                date = f"{C.RED}{timestamp_to_jalali(u['o_ex'])}{C.NC}"
            else:
                status = f"{C.GREEN}UPDATED{C.NC} "
                traf = f"{format_volume(u['o_tf'])}→{C.YELLOW}{format_volume(u['n_tf'])}{C.NC}"
                date = f"{timestamp_to_jalali(u['o_ex'])}→{C.GREEN}{timestamp_to_jalali(u['n_ex'])}{C.NC}"
            
            vis_len_traf = get_visual_len(traf)
            pad_traf = max(0, W_TRAF - 2 - vis_len_traf)
            traf_str = traf + (" " * pad_traf)

            vis_len_date = get_visual_len(date)
            pad_date = max(0, W_DATE - 2 - vis_len_date)
            date_str = date + (" " * pad_date)

            print(f"{C.BOX}│{C.NC} {idx:02d} {C.BOX}│{C.NC} {C.WHITE}{name:<{W_NAME-2}}{C.NC} {C.BOX}│{C.NC} {status} {C.BOX}│{C.NC} {traf_str} {C.BOX}│{C.NC} {date_str} {C.BOX}│{C.NC}")
        
        print(f"{C.BOX}└{'─'*W_ID}┴{'─'*W_NAME}┴{'─'*W_STAT}┴{'─'*W_TRAF}┴{'─'*W_DATE}┘{C.NC}")
        
        with open(log_file, 'w') as f:
            f.write(f"--- REPORT {datetime.datetime.now()} ---\n")
            for u in updated_log:
                f.write(f"{u['name']} | {u['status']} | {u['o_tf']}->{u['n_tf']}\n")

except Exception as e:
    print(f"\n{C.RED}🔥 Error: {e}{C.NC}")
    import traceback
    traceback.print_exc()
EOF

    # ==========================================
    # FINAL ACTIONS (BASH)
    # ==========================================
    
    echo -e "\n${YELLOW}⚡ Restarting X-UI Panel...${NC}"
    # Restart Command - Systemd is safer
    systemctl restart x-ui > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ Panel Restarted Successfully.${NC}"
    else
        # Fallback
        x-ui restart > /dev/null 2>&1
        if [ $? -eq 0 ]; then
             echo -e "${GREEN}✔ Panel Restarted Successfully.${NC}"
        else
             echo -e "${RED}❌ Panel Restart Failed (Check logs)${NC}"
        fi
    fi

    # FINAL SUMMARY
    CURRENT_DIR=$(pwd)
    echo -e "\n${BG_GREEN}${BWHITE}   ✔ OPERATION COMPLETED   ${NC}"
    
    # Using printf for fixed width to ensure the box is always closed properly
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC} %-72s ${CYAN}║${NC}\n" "SUMMARY & PATHS"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    printf "${CYAN}║${NC} ${PURPLE}%-13s${NC} ${WHITE}%-58s${NC} ${CYAN}║${NC}\n" "Backup Path:" "$BACKUP_DIR/x-ui.db"
    printf "${CYAN}║${NC} ${PURPLE}%-13s${NC} ${WHITE}%-58s${NC} ${CYAN}║${NC}\n" "Report File:" "$CURRENT_DIR/$LOG_FILE"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
}

# ==========================================
# MAIN LOOP
# ==========================================
while true; do
    show_menu
    read -p " ➤ Select: " choice
    case $choice in
        0)
            run_manager
            echo ""
            echo -e "${BBLUE}➜ Press Enter to return to main menu...${NC}"
            read
            ;;
        1)
            clear
            print_logo
            echo -e "${BCYAN}╔════════════════════════════════════════════════════╗${NC}"
            echo -e "${BCYAN}║${NC}                    ${BPURPLE}ABOUT SCRIPT${NC}                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}╠════════════════════════════════════════════════════╣${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}This tool manages X-UI via SQLite.${NC}                 ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}Code by: ${BGREEN}worldof01${NC}                                 ${BCYAN}║${NC}"            
            echo -e "${BCYAN}║${NC} ${BWHITE}GitHub : ${BLUE}https://github.com/worldof01${NC}              ${BCYAN}║${NC}"
            echo -e "${BCYAN}╠════════════════════════════════════════════════════╣${NC}"
            echo -e "${BCYAN}║${NC}                    ${BYELLOW}DONATE (TON)${NC}                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BWHITE}Buy me a coffee if you liked it!${NC}                   ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}                                                    ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC} ${BYELLOW}Tonkeeper Wallet Address:${NC}                          ${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}                                                    ${BCYAN}║${NC}"
            
            PAD="          "
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  ▄▄▄▄▄▄▄  ▄   ▄▄▄ ▄▄▄▄▄▄▄      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █ ▄▄▄ █ ▀ ▀█▄▀██ █ ▄▄▄ █      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █ ███ █ ▀█▀ ▄▀ █ █ ███ █      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █▄▄▄▄▄█ █ █ █▀▄█ █▄▄▄▄▄█      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  ▄▄▄▄  ▄ ▄▄▄▄▀ ▄▄   ▄ ▄ ▄      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █▀▄▀▀ ▄▀█▀▀▀▀█▀▄▀▄▀▄█▀ █      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █ █▀▀▄▄  █▀▀ ▀▄█ █▄ █ ▀█      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  ▄▄▄▄▄▄▄ █▄▄ ▀▄▀█ ▄ █ ▀▀█      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █ ▄▄▄ █ ▄ █▄█ ▄█▄▄▄█ █▄█      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  █ ███ █ █▀▄▀ ▀▄▀ █▄▀█▀▄█      ${NC}${PAD}${BCYAN}║${NC}"
            echo -e "${BCYAN}║${NC}${PAD}${BBLUE}  ▀▀▀▀▀▀▀ ▀   ▀  ▀   ▀   ▀      ${NC}${PAD}${BCYAN}║${NC}"
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