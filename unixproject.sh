#!/bin/bash

# =============================================
#        SYSTEM HEALTH MONITORING SUITE
#               macOS EDITION
#     (With Advanced ASCII Graph Analyzer + Live)
# =============================================

LOGFILE="system_health.log"
BACKUP_DIR="backup_$(date +%Y-%m-%d_%H-%M-%S)"

# ---------- COLORS ----------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗"
    echo -e "║   SYSTEM HEALTH MONITORING SUITE      ║"
    echo -e "║          macOS Version                ║"
    echo -e "╚═══════════════════════════════════════╝${RESET}"
    echo
}

# ===================================================
#                   CPU USAGE
# ===================================================
cpu_usage() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  CPU USAGE${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    CPU=$(ps -A -o %cpu 2>/dev/null | awk '{s+=$1} END {printf("%.2f", s)}')
    
    if [ -z "$CPU" ] || [ "$CPU" == "" ]; then
        echo "  ${RED}Error: Could not determine CPU usage${RESET}"
        return
    fi
    
    echo -e "  Current CPU Usage: ${GREEN}${CPU}%${RESET}"
    echo "$(date '+%a %b %d %H:%M:%S IST %Y') - CPU: ${CPU}%" >> "$LOGFILE"

    if (( $(echo "$CPU > 80" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "  ${RED}⚠ WARNING: CPU usage above 80%!${RESET}"
        echo "$(date '+%a %b %d %H:%M:%S IST %Y') - ALERT: CPU exceeded 80%" >> "$LOGFILE"
    else
        echo -e "  ${GREEN}✓ CPU usage is normal${RESET}"
    fi
    echo
}

# ===================================================
#                   MEMORY USAGE
# ===================================================
memory_usage() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  MEMORY USAGE${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    TOTAL=$(sysctl -n hw.memsize 2>/dev/null)
    FREE_PAGES=$(vm_stat 2>/dev/null | awk '/free/ {print $3}' | sed 's/\.//')
    PAGE_SIZE=$(sysctl -n hw.pagesize 2>/dev/null)

    if [ -z "$FREE_PAGES" ] || [ -z "$PAGE_SIZE" ] || [ -z "$TOTAL" ]; then
        echo "  ${RED}Error: Could not determine memory stats${RESET}"
        return
    fi

    FREE=$((FREE_PAGES * PAGE_SIZE))
    USED=$((TOTAL - FREE))
    MEM_PERCENT=$(echo "$USED/$TOTAL*100" | bc -l 2>/dev/null | xargs printf "%.2f" 2>/dev/null)

    if [ -z "$MEM_PERCENT" ]; then
        echo "  ${RED}Error: Could not calculate memory percentage${RESET}"
        return
    fi

    echo -e "  RAM Usage: ${GREEN}${MEM_PERCENT}%${RESET}"
    echo "$(date '+%a %b %d %H:%M:%S IST %Y') - RAM: ${MEM_PERCENT}%" >> "$LOGFILE"

    if (( $(echo "$MEM_PERCENT > 80" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "  ${RED}⚠ WARNING: Memory usage above 80%!${RESET}"
        echo "$(date '+%a %b %d %H:%M:%S IST %Y') - ALERT: RAM exceeded 80%" >> "$LOGFILE"
    else
        echo -e "  ${GREEN}✓ Memory usage is normal${RESET}"
    fi
    echo
}

# ===================================================
#                   DISK USAGE
# ===================================================
disk_usage() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  DISK USAGE${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    DISK=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ -z "$DISK" ]; then
        echo "  ${RED}Error: Could not determine disk usage${RESET}"
        return
    fi
    
    echo -e "  Disk Usage: ${GREEN}${DISK}%${RESET}"
    echo "$(date '+%a %b %d %H:%M:%S IST %Y') - Disk: ${DISK}%" >> "$LOGFILE"

    if [ "$DISK" -gt 80 ] 2>/dev/null; then
        echo -e "  ${RED}⚠ WARNING: Disk usage above 80%!${RESET}"
        echo "$(date '+%a %b %d %H:%M:%S IST %Y') - ALERT: Disk exceeded 80%" >> "$LOGFILE"
    else
        echo -e "  ${GREEN}✓ Disk usage is normal${RESET}"
    fi
    echo
}

# ===================================================
#              TOP PROCESSES (macOS)
# ===================================================
top_processes() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  TOP 5 CPU PROCESSES${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    ps -Ao pid,ppid,command,%cpu,%mem 2>/dev/null | sort -k4 -nr | head -6

    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  TOP 5 MEMORY PROCESSES${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    ps -Ao pid,ppid,command,%cpu,%mem 2>/dev/null | sort -k5 -nr | head -6
    echo
}

# ===================================================
#              BACKUP SYSTEM
# ===================================================
take_backup() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  BACKUP SYSTEM${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    
    echo "  Creating backup directory..."
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "  ${RED}✗ Failed to create backup directory${RESET}"
        return
    fi

    echo "  Backing up Documents..."
    if [ -d ~/Documents ]; then
        cp -r ~/Documents "$BACKUP_DIR" 2>/dev/null
        echo -e "  ${GREEN}✓ Documents backed up${RESET}"
    else
        echo -e "  ${YELLOW}⚠ Documents folder not found${RESET}"
    fi

    echo "  Backing up system logs..."
    if [ -d /var/log ]; then
        cp -r /var/log "$BACKUP_DIR" 2>/dev/null
        echo -e "  ${GREEN}✓ System logs backed up${RESET}"
    else
        echo -e "  ${YELLOW}⚠ System logs not accessible${RESET}"
    fi

    echo
    echo -e "  ${GREEN}Backup completed!${RESET}"
    echo -e "  Location: ${CYAN}$BACKUP_DIR${RESET}"
    echo "$(date '+%a %b %d %H:%M:%S IST %Y') - Backup created at $BACKUP_DIR" >> "$LOGFILE"
    echo
}

# ===================================================
#                 VIEW LOGS
# ===================================================
view_logs() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  LOG FILE CONTENT (Last 20 entries)${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    
    if [ -f "$LOGFILE" ]; then
        tail -20 "$LOGFILE" 2>/dev/null
        echo
        TOTAL_LINES=$(wc -l < "$LOGFILE" 2>/dev/null)
        echo -e "  ${CYAN}Total log entries: ${TOTAL_LINES}${RESET}"
    else
        echo -e "  ${YELLOW}No logs found!${RESET}"
    fi
    echo
}

# ===================================================
#       ADVANCED ASCII GRAPH LOG ANALYZER
# ===================================================
analyze_logs() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}  LOG ANALYZER – LAST 10 ENTRIES${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo

    if [ ! -f "$LOGFILE" ]; then
        echo "  ${YELLOW}No log file found!${RESET}"
        return
    fi

    # Extract only single metric entries (not combined live monitor entries)
    echo -e "${GREEN}─── CPU USAGE (Last 10) ───${RESET}\n"
    CPU_COUNT=$(grep "CPU:" "$LOGFILE" 2>/dev/null | grep -v "|" | wc -l | tr -d ' ')
    
    if [ "$CPU_COUNT" -eq 0 ]; then
        echo -e "  ${YELLOW}No CPU data available${RESET}"
    else
        grep "CPU:" "$LOGFILE" | grep -v "|" | awk -F"CPU: " '{print $2}' | sed 's/%//' | tail -10 | nl | \
        while read line value; do
            # Validate it's a number
            if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                bars=$(printf "%.0f" "$value" 2>/dev/null)
                [ -z "$bars" ] && bars=0
                printf "  ${CYAN}%2s${RESET} │ " "$line"
                for ((i=0; i<bars && i<100; i+=2)); do printf "${GREEN}█${RESET}"; done
                printf " ${YELLOW}%s%%${RESET}\n" "$value"
            fi
        done
    fi

    echo -e "\n${GREEN}─── RAM USAGE (Last 10) ───${RESET}\n"
    RAM_COUNT=$(grep "RAM:" "$LOGFILE" 2>/dev/null | grep -v "|" | wc -l | tr -d ' ')
    
    if [ "$RAM_COUNT" -eq 0 ]; then
        echo -e "  ${YELLOW}No RAM data available${RESET}"
    else
        grep "RAM:" "$LOGFILE" | grep -v "|" | awk -F"RAM: " '{print $2}' | sed 's/%//' | tail -10 | nl | \
        while read line value; do
            if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                bars=$(printf "%.0f" "$value" 2>/dev/null)
                [ -z "$bars" ] && bars=0
                printf "  ${CYAN}%2s${RESET} │ " "$line"
                for ((i=0; i<bars && i<100; i+=2)); do printf "${BLUE}█${RESET}"; done
                printf " ${YELLOW}%s%%${RESET}\n" "$value"
            fi
        done
    fi

    echo -e "\n${GREEN}─── DISK USAGE (Last 10) ───${RESET}\n"
    DISK_COUNT=$(grep "Disk:" "$LOGFILE" 2>/dev/null | grep -v "|" | wc -l | tr -d ' ')
    
    if [ "$DISK_COUNT" -eq 0 ]; then
        echo -e "  ${YELLOW}No Disk data available${RESET}"
    else
        grep "Disk:" "$LOGFILE" | grep -v "|" | awk -F"Disk: " '{print $2}' | sed 's/%//' | tail -10 | nl | \
        while read line value; do
            if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                bars=$(printf "%.0f" "$value" 2>/dev/null)
                [ -z "$bars" ] && bars=0
                printf "  ${CYAN}%2s${RESET} │ " "$line"
                for ((i=0; i<bars && i<100; i+=2)); do printf "${RED}█${RESET}"; done
                printf " ${YELLOW}%s%%${RESET}\n" "$value"
            fi
        done
    fi
    echo
}

# ===================================================
#              REAL-TIME LIVE MONITOR (AUTO-REFRESH)
# ===================================================
live_monitor() {
    trap 'echo -e "\n${GREEN}Exiting live monitor...${RESET}"; tput cnorm 2>/dev/null; return' SIGINT SIGTERM

    tput civis 2>/dev/null
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════╗"
        echo -e "║        LIVE SYSTEM MONITOR            ║"
        echo -e "║    (Updates every 2s - Ctrl+C exit)   ║"
        echo -e "╚═══════════════════════════════════════╝${RESET}"
        echo

        # CPU
        CPU=$(ps -A -o %cpu 2>/dev/null | awk '{s+=$1} END {printf("%.2f", s)}')
        
        # MEM
        TOTAL=$(sysctl -n hw.memsize 2>/dev/null)
        FREE_PAGES=$(vm_stat 2>/dev/null | awk '/free/ {print $3}' | sed 's/\.//')
        PAGE_SIZE=$(sysctl -n hw.pagesize 2>/dev/null)
        if [ -n "$TOTAL" ] && [ -n "$FREE_PAGES" ] && [ -n "$PAGE_SIZE" ]; then
            FREE=$((FREE_PAGES * PAGE_SIZE))
            USED=$((TOTAL - FREE))
            MEM_PERCENT=$(echo "$USED/$TOTAL*100" | bc -l 2>/dev/null | xargs printf "%.2f" 2>/dev/null)
        else
            MEM_PERCENT="N/A"
        fi
        
        # DISK
        DISK=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')

        # OUTPUT
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        printf "  ${YELLOW}CPU:${RESET}  %s%%\n" "${CPU:-N/A}"
        printf "  ${YELLOW}RAM:${RESET}  %s%%\n" "${MEM_PERCENT:-N/A}"
        printf "  ${YELLOW}DISK:${RESET} %s%%\n" "${DISK:-N/A}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo

        # Visual bars
        if [[ "$CPU" =~ ^[0-9]+\.?[0-9]*$ ]] && [ "$CPU" != "N/A" ]; then
            cpu_bars=$(printf "%.0f" "$CPU" 2>/dev/null)
            [ -z "$cpu_bars" ] && cpu_bars=0
            printf "  ${CYAN}CPU ${RESET} │ "
            for ((i=0;i<cpu_bars && i<100;i+=2)); do printf "${GREEN}█${RESET}"; done
            printf " ${YELLOW}%s%%${RESET}\n" "$CPU"
        fi

        if [[ "$MEM_PERCENT" =~ ^[0-9]+\.?[0-9]*$ ]] && [ "$MEM_PERCENT" != "N/A" ]; then
            mem_bars=$(printf "%.0f" "$MEM_PERCENT" 2>/dev/null)
            [ -z "$mem_bars" ] && mem_bars=0
            printf "  ${CYAN}RAM ${RESET} │ "
            for ((i=0;i<mem_bars && i<100;i+=2)); do printf "${BLUE}█${RESET}"; done
            printf " ${YELLOW}%s%%${RESET}\n" "$MEM_PERCENT"
        fi

        if [[ "$DISK" =~ ^[0-9]+$ ]] && [ "$DISK" != "N/A" ]; then
            disk_bars=$(printf "%.0f" "$DISK" 2>/dev/null)
            [ -z "$disk_bars" ] && disk_bars=0
            printf "  ${CYAN}DISK${RESET} │ "
            for ((i=0;i<disk_bars && i<100;i+=2)); do printf "${RED}█${RESET}"; done
            printf " ${YELLOW}%s%%${RESET}\n" "$DISK"
        fi

        echo
        echo -e "${YELLOW}Top 5 Processes (CPU)${RESET}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        ps -Ao pid,ppid,%cpu,%mem,command 2>/dev/null | sort -k3 -nr | head -6
        echo

        # Log the current snapshot with proper format
        if [ "$CPU" != "N/A" ] && [ "$MEM_PERCENT" != "N/A" ] && [ "$DISK" != "N/A" ]; then
            echo "$(date '+%a %b %d %H:%M:%S IST %Y') - CPU: ${CPU}% | RAM: ${MEM_PERCENT}% | Disk: ${DISK}%" >> "$LOGFILE"
        fi

        sleep 2
    done
    tput cnorm 2>/dev/null
    trap - SIGINT SIGTERM
}

# ===================================================
#                     MENU
# ===================================================
while true; do
    header
    echo -e "${MAGENTA}╔═══════════════════════════════════════╗"
    echo -e "║              MAIN MENU                ║"
    echo -e "╚═══════════════════════════════════════╝${RESET}"
    echo
    echo -e "  ${BLUE}[1]${RESET} Check CPU Usage"
    echo -e "  ${BLUE}[2]${RESET} Check Memory Usage"
    echo -e "  ${BLUE}[3]${RESET} Check Disk Usage"
    echo -e "  ${BLUE}[4]${RESET} Show Top Processes"
    echo -e "  ${BLUE}[5]${RESET} Take System Backup"
    echo -e "  ${BLUE}[6]${RESET} View Logs"
    echo -e "  ${BLUE}[7]${RESET} Analyze Logs (Advanced Graphs)"
    echo -e "  ${BLUE}[8]${RESET} Live Monitor (Auto-refresh)"
    echo -e "  ${BLUE}[9]${RESET} Exit"
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -p "$(echo -e ${YELLOW}Enter your choice:${RESET} )" ch

    case $ch in
        1) cpu_usage ;;
        2) memory_usage ;;
        3) disk_usage ;;
        4) top_processes ;;
        5) take_backup ;;
        6) view_logs ;;
        7) analyze_logs ;;
        8) live_monitor ;;
        9) echo -e "\n${GREEN}✓ Exiting... Goodbye!${RESET}\n"; tput cnorm 2>/dev/null; exit 0 ;;
        *) echo -e "\n${RED}✗ Invalid option. Please try again.${RESET}\n" ;;
    esac

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}Press ENTER to continue...${RESET}"
    read
done