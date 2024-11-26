#!/bin/bash
# File Names
BOOK_FILE="books.txt"
STUDENT_FILE="students.txt"
ADMIN_FILE="admin.txt"
BORROWED_FILE="borrowed.txt"
BOOK_ID_FILE="last_book_id.txt"  # File to store the last used book ID
LOGIN_STATUS=0  # 0 - not logged in, 1 - logged in as admin, 2 - logged in as student
LOGGED_STUDENT_ID=0  # Store the logged-in student ID

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to center text and handle color codes properly
center_text() {
    text=$1
    width=$(tput cols)  # Get the width of the terminal
    padding=$((($width - ${#text}) / 2))
    printf "%${padding}s%s\n" "" "$text"
}

# Ensure all required files exist
echo "Ensuring necessary files exist..."
for file in "$BOOK_FILE" "$STUDENT_FILE" "$ADMIN_FILE" "$BORROWED_FILE"; do
    if [ ! -f "$file" ]; then
        touch "$file" || echo -e "${RED}Failed to create $file${NC}"
    fi
done

# Ensure last_book_id.txt exists and initialize it if necessary
if [ ! -f "$BOOK_ID_FILE" ]; then
    echo 0 > "$BOOK_ID_FILE"
fi

# Function to get the next available Book ID
get_next_book_id() {
    last_book_id=$(cat "$BOOK_ID_FILE")
    next_book_id=$((last_book_id + 1))
    echo "$next_book_id"
    echo "$next_book_id" > "$BOOK_ID_FILE"  # Update the last used ID
}

# Admin Login Function
admin_login() {
    clear
    echo # Add space
    center_text "${BOLD}Admin Portal"  # Centered and bold
    echo # Add space

    # Loop until successful login or empty credentials
    while true; do
        echo "Enter Admin Username (or press Enter to return to main menu):"
        read username

        # If username is empty, go back to the main menu
        if [[ -z "$username" ]]; then
            echo -e "${YELLOW}Returning to main menu...${NC}"
            clear
            main_menu
            return  # Exit the function
        fi

        echo "Enter Admin Password (or press Enter to return to main menu):"
        read -s password

        # If password is empty, go back to the main menu
        if [[ -z "$password" ]]; then
            echo -e "${YELLOW}Returning to main menu...${NC}"
            clear
            main_menu
            return  # Exit the function
        fi

        # Check if the username exists in the admin file
        admin_record=$(grep "^$username|" "$ADMIN_FILE")

        if [[ -z $admin_record ]]; then
            echo -e "${RED}Invalid username!${NC}"
            echo -e "${YELLOW}Press Enter to try again...${NC}"
            read
            clear
            continue  # Retry login
        fi
        # Extract the stored password and check if it matches
        stored_password=$(echo $admin_record | cut -d'|' -f2)
        if [[ "$password" != "$stored_password" ]]; then
            echo -e "${RED}Invalid password!${NC}"
            echo -e "${YELLOW}Press Enter to try again...${NC}"
            read
            clear
            continue  # Retry login
        fi
        # Successful login
        LOGIN_STATUS=1
        echo -e "${GREEN}Admin logged in successfully!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        clear
        admin_menu
        break  # Exit the loop and proceed to the admin menu
    done
}

# Student Login Function
student_login() {
    clear
    echo # Add space
    center_text "${BOLD}Student Portal"  # Centered and bold
    echo # Add space

    # Loop until successful login or empty credentials
    while true; do
        echo "Enter Student Admission Number (or press Enter to return to main menu):"
        read admission_no

        # If admission number is empty, go back to the main menu
        if [[ -z "$admission_no" ]]; then
            echo -e "${YELLOW}Returning to main menu...${NC}"
            clear
            main_menu
            return  # Exit the function
        fi

        echo "Enter Student Password (or press Enter to return to main menu):"
        read -s password

        # If password is empty, go back to the main menu
        if [[ -z "$password" ]]; then
            echo -e "${YELLOW}Returning to main menu...${NC}"
            clear
            main_menu
            return  # Exit the function
        fi

        # Search for the student record
        student_record=$(grep "^$admission_no|[^|]*|$password|[^|]*" "$STUDENT_FILE")

        if [[ -z $student_record ]]; then
            echo -e "${RED}Invalid admission number or password!${NC}"
            echo -e "${YELLOW}Press Enter to try again...${NC}"
            read
            clear
            continue  # Retry login
        fi

        # Successfully logged in as student
        LOGIN_STATUS=2
        LOGGED_STUDENT_ID=$admission_no
        echo -e "${GREEN}Student logged in successfully!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        clear
        student_menu
        break  # Exit the loop and proceed to the student menu
    done
}
# Student Registration Function
register_student() {
    clear
    echo # Add space
    center_text "${BOLD}Register"  # Centered and bold
    echo # Add space
    admission_no=$(date +%s)
    echo -e "${GREEN}Generated Admission Number: $admission_no${NC}"
    
    echo "Enter Student Name:"
    read student_name
    echo "Enter Password:"
    read -s password
    
    # Check if either field is empty
    if [[ -z $student_name || -z $password ]]; then
        echo -e "${RED}Invalid credentials! Both fields are required.${NC}"
        echo -e "${YELLOW}You will be returned to the main menu. Press Enter to continue...${NC}"
        read
        clear  # Clear the screen before returning to the main menu
        main_menu  # Return to the main menu
        return  # Ensure the function exits and does not proceed with registration
    fi

    # Append new student to the file
    echo "$admission_no|$student_name|$password|0|" >> "$STUDENT_FILE"
    echo -e "${GREEN}Student Registered Successfully with Admission Number: $admission_no${NC}"
    echo -e "${YELLOW}Please save this number for login. Press Enter to continue...${NC}"
    read
    
    # Clear the screen before returning to main menu
    clear
    main_menu  # Return to the main menu
}


# Admin Menu
admin_menu() {
    while true; do
        clear
        center_text "${BOLD}Admin Menu"  # Centered and bold
        echo # Add space
        echo "1. Add Book"
        echo "2. Remove Book"
        echo "3. View Books"
        echo "4. Issue Book"
        echo "5. Return Book"
        echo "6. View Borrowed Books"
        echo "7. Logout"
        read -p "Choose an option: " option
        
        case $option in
            1) add_book;;
            2) remove_book;;
            3) view_books;;
            4) issue_book;;
            5) return_book;;
            6) view_borrowed_books_status;;
            7) main_menu;;
            *) echo -e "${RED}Invalid option!${NC}";;
        esac
    done
}

# Student Menu
student_menu() {
    while true; do
        clear
        center_text "${BOLD}Student Menu"  # Centered and bold
        echo # Add space
        echo "1. View Available Books"
        echo "2. Borrow Book"
        echo "3. Return Book"
        echo "4. View Borrowed Books and Status"
        echo "5. Search Book by Title/Author"
        echo "6. Delete My Registration"
        echo "7. Logout"
        read -p "Choose an option: " option
        
        case $option in
            1) view_books;;
            2) borrow_book;;  # Borrow book
            3) return_book;;
            4) view_borrowed_books_status;;
            5) search_book;;
            6) delete_student_registration;;
            7) logout_student;;
            *) echo -e "${RED}Invalid option!${NC}";;
        esac
    done
}

# Add Book
add_book() {
    clear
    echo # Add space
    echo "Enter Book Name:"
    read book_name
    echo "Enter Author Name:"
    read author_name

    if [[ -z $book_name || -z $author_name ]]; then
        echo -e "${RED}Invalid input! Book name and author name are required.${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi

    # Check if the book already exists (same name and author)
    if grep -q "^.*|$book_name|$author_name" "$BOOK_FILE"; then
        echo -e "${RED}This book already exists in the system!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi

    book_id=$(get_next_book_id)
    echo "$book_id|$book_name|$author_name|Available" >> "$BOOK_FILE"
    echo -e "${GREEN}Book added successfully with ID: $book_id${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    admin_menu
}

# Remove Book
remove_book() {
    clear
     echo # Add space
    echo "Enter Book ID to remove:"
    read book_id

    if grep -q "^$book_id|" "$BOOK_FILE"; then
        sed -i "/^$book_id|/d" "$BOOK_FILE"
        echo -e "${GREEN}Book removed successfully!${NC}"
    else
        echo -e "${RED}Book ID not found!${NC}"
    fi

    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    admin_menu
}

# View Books
view_books() {
    clear
     echo # Add space
    echo "All Books:"
    echo -e "ID     | Name                | Author              | Status     "
    echo -e "--------------------------------------------------------------"
    awk -F'|' '{ printf "%-6s | %-18s | %-20s | %-12s\n", $1, $2, $3, $4 }' "$BOOK_FILE"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    if [ $LOGIN_STATUS -eq 1 ]; then
        admin_menu
    else
        student_menu
    fi
}

# Issue Book (Admin only)
issue_book() {
    clear
    echo # Add space
    echo "Enter Book ID to issue:"
    read book_id

    # Check if the book exists
    book=$(grep "^$book_id|" "$BOOK_FILE")
    if [[ -z $book ]]; then
        echo -e "${RED}Book ID not found!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi
    book_status=$(echo $book | cut -d'|' -f4)
    if [[ "$book_status" != "Available" ]]; then
        echo -e "${RED}Sorry, the book is already borrowed.${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi

    # Ask for the student's admission number and name
    echo "Enter Student Admission Number:"
    read student_admission_no
    student_name=$(grep "^$student_admission_no|" "$STUDENT_FILE" | cut -d'|' -f2)

    if [[ -z $student_name ]]; then
        echo -e "${RED}Invalid student admission number!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi

    # Ask for the deadline for book return (e.g., 2024-12-31)
    echo "Enter Deadline (YYYY-MM-DD) for returning the book:"
    read return_deadline

    # Validate the deadline format (simple check)
    if [[ ! "$return_deadline" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}Invalid date format! Please use YYYY-MM-DD.${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi
    # Mark the book as borrowed
    sed -i "s/^$book_id|[^|]*|[^|]*|Available$/$book_id|$(echo $book | cut -d'|' -f2)|$(echo $book | cut -d'|' -f3)|Borrowed/" "$BOOK_FILE"
    # Record the borrowing with the deadline in BORROWED_FILE
    echo "$book_id|$student_admission_no|$student_name|$return_deadline" >> "$BORROWED_FILE"
    echo -e "${GREEN}Book issued successfully to student: $student_name (Admission No: $student_admission_no) with a return deadline of $return_deadline.${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    admin_menu
}

borrow_book() {
    clear
    echo # Add space
    echo "Enter Book ID to borrow:"
    read book_id
    book=$(grep "^$book_id|" "$BOOK_FILE")
    if [[ -z $book ]]; then
        echo -e "${RED}Book ID not found!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi

    book_status=$(echo $book | cut -d'|' -f4)
    if [[ "$book_status" != "Available" ]]; then
        echo -e "${RED}Sorry, the book is already borrowed.${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi

    # Calculate due date (15 days from today)
    due_date=$(date -d "+15 days" +"%Y-%m-%d")

    # Mark book as borrowed
    sed -i "s/^$book_id|[^|]*|[^|]*|Available$/$book_id|$(echo $book | cut -d'|' -f2)|$(echo $book | cut -d'|' -f3)|Borrowed/" "$BOOK_FILE"

    # Add to borrowed list with due date
    echo "$book_id|$LOGGED_STUDENT_ID|$LOGGED_STUDENT_NAME|$due_date" >> "$BORROWED_FILE"

    echo -e "${GREEN}Book borrowed successfully! Due Date: $due_date.${NC}"
    echo -e "${RED}Return after due date will cause Penalty( 100 PKR per day).${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    student_menu
}
# Return Book
return_book() {
    clear
    echo # Add space
    echo "Enter Book ID to return:"
    read book_id

    # Ask for student's admission number
    echo "Enter Student Admission Number:"
    read student_admission_no

    # Ensure the entered admission number matches the logged-in student ID
    if [[ "$student_admission_no" != "$LOGGED_STUDENT_ID" ]]; then
        echo -e "${RED}Invalid student admission number!${NC}"
        echo -e "${YELLOW}Press Enter to try again...${NC}"
        read
        return  # Exit if admission numbers do not match
    fi

    # Check if the book is borrowed by the logged-in student
    if ! grep -q "^$book_id|$student_admission_no" "$BORROWED_FILE"; then
        echo -e "${RED}You haven't borrowed this book!${NC}"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return  # Exit if the student has not borrowed this book
    fi

    # Mark book as available
    book=$(grep "^$book_id" "$BOOK_FILE")
    sed -i "s/^$book_id|[^|]*|[^|]*|Borrowed$/$book_id|$(echo $book | cut -d'|' -f2)|$(echo $book | cut -d'|' -f3)|Available/" "$BOOK_FILE"
    
    # Remove the book from the borrowed list
    sed -i "/^$book_id|$student_admission_no/d" "$BORROWED_FILE"
    
    echo -e "${GREEN}Book returned successfully!${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    student_menu
}

search_book() {
    clear
    echo # Add space
    echo "Enter search keyword (title or author):"
    read keyword

    # Check if the user entered a keyword
    if [[ -z "$keyword" ]]; then
        echo -e "${RED}Please enter a valid keyword!${NC}"
    else
        matches=$(grep -i "$keyword" "$BOOK_FILE")
        if [[ -z $matches ]]; then
            echo -e "${RED}No matching books found!${NC}"
        else
            echo "Matching Books:"
            echo -e "ID     | Name                | Author              | Status     "
            echo -e "--------------------------------------------------------------"
            echo "$matches" | awk -F'|' '{ printf "%-6s | %-18s | %-20s | %-12s\n", $1, $2, $3, $4 }'
        fi
    fi

    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    student_menu
}

# Delete Student Registration
delete_student_registration() {
    clear
    echo # Add space
    echo "Are you sure you want to delete your registration? (y/n)"
    read confirmation

    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        sed -i "/^$LOGGED_STUDENT_ID|/d" "$STUDENT_FILE"
        echo -e "${GREEN}Registration deleted successfully!${NC}"
        LOGGED_STUDENT_ID=0
        LOGIN_STATUS=0
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        clear
        main_menu
    else
        student_menu
    fi
}

view_borrowed_books_status() {
    clear
    echo # Add space
    if [ $LOGIN_STATUS -eq 1 ]; then  # Admin view
        echo "Borrowed Books (Admin View):"
        # Admin sees all borrowed books with student names
        awk -F'|' '{ printf "Book ID: %-6s | Student ID: %-6s | Student Name: %-20s | Due Date: %-12s\n", $1, $2, $3, $4 }' "$BORROWED_FILE"
    else  # Student view
        echo "Your Borrowed Books:"
        # Show books for the logged-in student with due date
        awk -F'|' -v student_id="$LOGGED_STUDENT_ID" '$2 == student_id { printf "Book ID: %-6s | Due Date: %-12s\n", $1, $4 }' "$BORROWED_FILE"
    fi
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    # Return to the correct menu based on login status
    if [ $LOGIN_STATUS -eq 1 ]; then
        admin_menu
    else
        student_menu
    fi
}



# Student Logout
logout_student() {
    LOGIN_STATUS=0
    LOGGED_STUDENT_ID=0
    echo -e "${GREEN}You have logged out successfully!${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
    clear
    main_menu
}

# Main Menu
main_menu() {
    clear
    echo # Add space
    center_text "${BOLD}Library Management System"  # Centered and bold
    echo # Add space
    echo "1. Admin"
    echo "2. Student"
    echo "3. Register as Student"
    echo "4. Exit"
    read -p "Choose an option: " option

    case $option in
        1) admin_login;;
        2) student_login;;
        3) register_student;;
        4) exit 0;;
        *) echo -e "${RED}Invalid option!${NC}";;
    esac
}

# Run the Main Menu initially
main_menu