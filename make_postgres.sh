#!/bin/bash
DB_USER="${POSTGRES_USER:-user}"
DB_PASS="${POSTGRES_PASSWORD:-password}"
DB_NAME="${POSTGRES_DB:-mydatabase}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
    exit 1
}

log_info "Starting PostgreSQL setup for the bot..."

if [[ $EUID -ne 0 ]]; then
    if ! command_exists sudo; then
        log_error "sudo command not found. Please run this script as root or install sudo."
    fi
    log_info "Requesting sudo privileges for system operations (like package installation)..."
    sudo -v
    if [[ $? -ne 0 ]]; then
        log_error "Failed to obtain sudo privileges. Exiting."
    fi
fi

if ! command_exists psql; then
    log_info "psql command not found. Attempting to install PostgreSQL..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y postgresql postgresql-client
        if [[ $? -ne 0 ]]; then
            log_error "Failed to install PostgreSQL. Please install it manually and re-run this script."
        fi
        log_info "PostgreSQL installed successfully."
    else
        log_warn "apt-get not found. Cannot automatically install PostgreSQL."
        log_error "Please install PostgreSQL and psql client manually, then re-run this script."
    fi
else
    log_info "PostgreSQL client (psql) is already installed."
fi

if command_exists systemctl; then
    if ! sudo systemctl is-active --quiet postgresql; then
        log_info "PostgreSQL service is not active. Attempting to start and enable it..."
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        sleep 3
        if ! sudo systemctl is-active --quiet postgresql; then
            log_error "Failed to start PostgreSQL service. Please check the service status manually (e.g., journalctl -u postgresql)."
        fi
        log_info "PostgreSQL service started and enabled."
    else
        log_info "PostgreSQL service is active."
    fi
else
    log_warn "systemctl not found. Cannot automatically check or start PostgreSQL service."
    log_info "Please ensure the PostgreSQL server is running."
fi

log_info "Waiting a few seconds for PostgreSQL to initialize..."
sleep 5

log_info "Attempting to create PostgreSQL user '$DB_USER' and database '$DB_NAME'..."
ADMIN_PSQL_CMD="env PGHOST= PGHOSTADDR= psql -U postgres -d template1"

if sudo -u postgres $ADMIN_PSQL_CMD -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    log_info "User '$DB_USER' already exists."
    log_info "Ensuring password for user '$DB_USER' is up to date..."
    sudo -u postgres $ADMIN_PSQL_CMD -c "ALTER USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"
    if [[ $? -ne 0 ]]; then
        log_warn "Failed to update password for existing user '$DB_USER'. This might not be an issue if password is correct."
    fi
else
    log_info "Creating user '$DB_USER'..."
    sudo -u postgres $ADMIN_PSQL_CMD -c "CREATE USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"
    if [[ $? -ne 0 ]]; then
        log_warn "Failed to create user '$DB_USER' with password. It might already exist without a password, or another issue occurred. Attempting to set password."
        sudo -u postgres $ADMIN_PSQL_CMD -c "ALTER USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"
        if [[ $? -ne 0 ]]; then
            log_error "Still failed to ensure user '$DB_USER' is configured with the password. Please check PostgreSQL logs and pg_hba.conf."
        else
            log_info "Password set for user '$DB_USER'."
        fi
    else
        log_info "User '$DB_USER' created successfully."
    fi
fi

if sudo -u postgres $ADMIN_PSQL_CMD -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    log_info "Database '$DB_NAME' already exists."
    DB_OWNER=$(sudo -u postgres $ADMIN_PSQL_CMD -tAc "SELECT pg_catalog.pg_get_userbyid(d.datdba) FROM pg_catalog.pg_database d WHERE d.datname = '$DB_NAME'")
    if [[ "$DB_OWNER" != "$DB_USER" ]]; then
        log_info "Database '$DB_NAME' owner is '$DB_OWNER'. Changing owner to '$DB_USER'."
        sudo -u postgres $ADMIN_PSQL_CMD -c "ALTER DATABASE \"$DB_NAME\" OWNER TO \"$DB_USER\";"
        if [[ $? -ne 0 ]]; then
            log_warn "Failed to change owner of database '$DB_NAME' to '$DB_USER'."
        fi
    else
        log_info "Database '$DB_NAME' owner is already '$DB_USER'."
    fi
else
    log_info "Creating database '$DB_NAME' with owner '$DB_USER' and encoding UTF8..."
    sudo -u postgres env PGHOST= PGHOSTADDR= createdb -U postgres -O "$DB_USER" -E UTF8 "$DB_NAME"
    if [[ $? -ne 0 ]]; then
        log_error "Failed to create database '$DB_NAME'. Please check PostgreSQL logs and pg_hba.conf."
    else
        log_info "Database '$DB_NAME' created successfully."
    fi
fi

log_info "Granting all privileges on database '$DB_NAME' to user '$DB_USER'..."
sudo -u postgres $ADMIN_PSQL_CMD -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\";"
if [[ $? -ne 0 ]]; then
    log_warn "Failed to grant all privileges on database '$DB_NAME' to '$DB_USER'."
fi

log_info "Connecting to database '$DB_NAME' as user '$DB_USER' to create 'subscriptions' table..."
CREATE_TABLE_SQL="
CREATE TABLE IF NOT EXISTS subscriptions (
    chat_id BIGINT PRIMARY KEY,
    keywords TEXT,
    field_of_study TEXT,
    subscription_period INTEGER,
    last_update DATE,
    max_results INTEGER,
    days INTEGER,
    review_only BOOLEAN,
    keyword_mode TEXT,
    detailed_query TEXT,
    min_citations INTEGER,
    databases TEXT,
    subscription_hour INTEGER,
    subscription_minute INTEGER
);
GRANT ALL PRIVILEGES ON TABLE subscriptions TO \"$DB_USER\";
"
export PGPASSWORD="$DB_PASS"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$CREATE_TABLE_SQL"
if [[ $? -ne 0 ]]; then
    unset PGPASSWORD
    log_error "Failed to create table 'subscriptions' or grant privileges in database '$DB_NAME' when connecting as '$DB_USER'. Check permissions and psql output."
fi
unset PGPASSWORD
log_info "Table 'subscriptions' created/configured successfully (or already existed) in database '$DB_NAME'."
log_info "PostgreSQL setup for the bot is complete!"
log_info "You should be able to connect using DSN: postgresql://$DB_USER:YOUR_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
log_warn "Remember to replace YOUR_PASSWORD with the actual password if displaying the DSN."
exit 0
