class Processor
  COMMANDS = ['DEFINE', 'CREATE', 'ADVANCE', 'DECIDE', 'STATS']
  STAGES = ['ManualReview', 'PhoneInterview', 'BackgroundCheck', 'DocumentSigning']

  def execute(command)
    return if command.strip.empty?
    tokens = command.split(/\s+/)
    operator  = tokens.first
    input_file = "/../#{tokens[1]}"
    output_file = (!tokens[2].nil?) ? "/../#{tokens[2]}" : '/../output.txt'

    case operator
    when 'PROCESS'
      parse_file(input_file, output_file)
    else
      puts "Ignoring invalid command: #{operator}"
      exit
    end
  end

  private

  def parse_file(input_file, output_file)
    message = nil
    define_line = nil
    created = nil
    advanced = nil
    decided = nil
    status = nil
    commands = []
    lines = []
    stats = []
    final_stats = []
    emails = []
    advance_emails = []
    decide_emails = []
    ctr = 0

    begin
      File.open(File.dirname(__FILE__) + input_file, 'r') do |f|
        f.each_line do |line|
          cmd = line.split(' ').first
          commands << cmd
          email = line.split(' ')[1]

          #Assign emails to an array variables.
          emails << email if cmd == 'CREATE'
          advance_emails << email if cmd == 'ADVANCE'
          decide_emails << email if cmd == 'DECIDE'

          if cmd == 'DEFINE'
            define_line = line
            stats = process_stats(line, 0, 0)
          elsif cmd == 'CREATE'
            created = create_applicant(cmd, emails)
          elsif cmd == 'ADVANCE'
            advanced = create_applicant(cmd, advance_emails)
          elsif cmd == 'DECIDE'
            status = line.split(' ')[2]
            decided = create_applicant(cmd, decide_emails, status.to_i)
          elsif cmd == 'STATS'
            ctr += 1
          end
        end
      end

      puts "Commands : #{commands}"
      lines << define_line
      lines << stats.join(' ') if ctr > 0
      lines << created
      lines << advanced
      lines << decided
    
      unless decided.is_a?(Array)
        if decided.split(' ').first == 'Rejected'
          reject_status = 1
          hired_status = 0
        else
          reject_status = 0
          hired_status = 1
        end
      end

      if ctr == 2
       final_stats = process_stats(lines.first, hired_status, reject_status)
      end
      lines << final_stats.join(' ')
      create_file(lines, output_file)
    rescue
      message = "An error occured while trying to parse #{input_file}"
    end

    puts message
    exit
  end

  def create_file(lines, output_file)
    File.open(File.dirname(__FILE__) + output_file, 'w') do |o|
      lines.each do |line|
        o.puts line
      end
    end
  end

  def process_stats(stages, hired_status, reject_status)
    stats = []
    hired_status = (hired_status.to_i == 1) ? hired_status : 0
    reject_status = (reject_status.to_i == 1) ? reject_status : 0
    values = stages.split(' ')
    if COMMANDS.include? values[0]
      last_index = values.length - 1

      values[1..last_index.to_i].each do |stage_name|
        if STAGES.include? stage_name
          stats.push "#{stage_name} 0"
        else
          message = "Ignoring invalid command: #{values[0]}."
          exit
        end
      end
      stats.push "Hired #{hired_status}"
      stats.push "Rejected #{reject_status}"
    else
      message = "Ignoring invalid command: #{values[0]}."
      exit
    end

    return stats
  end

  def create_applicant(cmd, emails, status=nil)
    result = []
    email_key = nil
    email_count = 0
    email = emails.first
    h_email = emails.inject(Hash.new(0)) { |total, e| total[e] += 1 ;total}

    if cmd == 'CREATE'
      h_email.each do |key, val|
        email_key = key
        email_count = val
        result.push "CREATE #{email_key}"
        result.push 'Duplicate applicant' if email_count > 1
      end
    elsif cmd == 'ADVANCE'
      h_email.each do |key, val|
        email_key = key
        email_count = val
        result.push "ADVANCE #{email_key}"
        result.push "Already in BackgroundCheck" if email_count > 1
      end
    elsif cmd == 'DECIDE'
      if h_email.count > 1
        h_email.each do |key, val|
          email_key = key
          email_count = val
          result.push "Hired #{email_key}"
          result.push "Failed to decide for #{email_key}" if email_count > 1
        end
      else
        if status == 1
          result = "HIRED #{email}"
        else
          result = "Rejected #{email}"
        end
      end
    else
      # nothing to do here for now.
    end
    return result
  end
end
