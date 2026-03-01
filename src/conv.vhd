library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Discreet convolutional: 
-- Let m = length(u) and n = length(v). Then w is the vector of length m+n-1 whose kth element is
-- w(k) = sum_j(u(j)*v(k-j))

entity conv is
  generic (
    LENGHT_MAX : integer := 7; -- Lenght max samples from signal u or v  
    LBITS : integer := 10   -- Size data of the input signal, u and v, and output signal, w.
    );
  port (clk   : in  std_ulogic; --Clock                               
        reset   : in  std_ulogic; -- Reset asincronous
        reset_sinc   : in  std_ulogic; -- Reset sincronous

        length_u : in std_ulogic_vector(LENGHT_MAX-1 downto 0); --number of signal u samples expected   
        length_v : in std_ulogic_vector(LENGHT_MAX-1 downto 0); --number of signal v samples expected 
        length_w : out std_ulogic_vector(LENGHT_MAX downto 0); -- length_w = length_u + length_v - 1

        -- Slave axi interface for input_1 signal u
        s_tvalid_u : in std_ulogic;
        s_tready_u : out std_ulogic;
        s_tdata_u : in std_ulogic_vector(LBITS-1 downto 0);

        -- Slave axi interface for input_2 signal v
        s_tvalid_v : in std_ulogic;
        s_tready_v : out std_ulogic;
        s_tdata_v : in std_ulogic_vector(LBITS-1 downto 0);
        
        -- Slave axi interface for output signal w
        m_tvalid_w : out std_ulogic;
        m_tready_w : in std_ulogic;
        m_tdata_w : out std_ulogic_vector(LBITS-1 downto 0)
        );
end conv;

architecture conv_arch of conv is

    -- Two signals needed for the firewall assertions
    signal firewall_length_u, firewall_length_v : std_ulogic_vector(LENGHT_MAX-1 downto 0) :=  (others =>'0');


    type state_mem is (REPOSO, STORE, WAIT_CONV);
    signal v_state_a, p_v_state_a,u_state_a, p_u_state_a : state_mem;

    type state_conv is (REPOSO, MULT, CONV_CALC);
    signal conv_state, p_conv_state : state_conv;

    signal len_u, len_v: unsigned(LENGHT_MAX downto 0); 

    signal rst_asinc_cont_u, rst_asinc_cont_v: std_ulogic;

    signal v_sample, u_sample : signed (LBITS-1 downto 0);

    signal index_v_sample, p_index_v_sample ,index_u_sample, p_index_u_sample : unsigned (LENGHT_MAX-1 downto 0) := (others=> '0'); 

    signal p_w_sample, w_sample: signed(LENGHT_MAX+LBITS*2-1 downto 0); -- Max value of w sample is (others=>'1')'length(LBITS)*(others=>'1')'length(LBITS)*(others=>'1')'length(LENGHT_MAX) 

    constant one_LENGHT_MAX: signed(LENGHT_MAX-1 downto 0) := (0 => '1', others=> '0');


    signal u_addri_a : unsigned (LENGHT_MAX-1 downto 0);          -- Address for port A
    signal u_datai_a : std_logic_vector (LBITS-1 downto 0);  -- Input data for port A
    signal u_we_a    : std_logic;                                 -- Write enable for port A
    signal u_datao_a : std_logic_vector (LBITS-1 downto 0);  -- Output data for port A
    signal u_addri_b : unsigned (LENGHT_MAX-1 downto 0);          -- Address for port B
    signal u_datai_b : std_logic_vector (LBITS-1 downto 0);  -- Input data for port B
    signal u_we_b    : std_logic;                                 -- Write enable for port B
    signal u_datao_b : std_logic_vector (LBITS-1 downto 0);   -- Output data for port B    

    signal v_addri_a : unsigned (LENGHT_MAX-1 downto 0);          -- Address for port A
    signal v_datai_a : std_logic_vector (LBITS-1 downto 0);  -- Input data for port A
    signal v_we_a    : std_logic;                                 -- Write enable for port A
    signal v_datao_a : std_logic_vector (LBITS-1 downto 0);  -- Output data for port A
    signal v_addri_b : unsigned (LENGHT_MAX-1 downto 0);          -- Address for port B
    signal v_datai_b : std_logic_vector (LBITS-1 downto 0);  -- Input data for port B
    signal v_we_b    : std_logic;                                 -- Write enable for port B
    signal v_datao_b : std_logic_vector (LBITS-1 downto 0);   -- Output data for port B    

begin

    -- Memory to storage signal u
    u_dpram: entity work.dpram
    generic map (
      DATA_WIDTH => LBITS,
      ADDR_WIDTH => LENGHT_MAX
    )
    port map (
      clk_a   => clk,
      clk_b   => clk,
      addri_a => u_addri_a,
      datai_a => u_datai_a,
      we_a    => u_we_a,
      datao_a => u_datao_a,
      addri_b => u_addri_b,
      datai_b => u_datai_b,
      we_b    => u_we_b,
      datao_b => u_datao_b
    );

    u_we_a <= s_tvalid_u and s_tready_u;
    u_we_b <= '0';
    u_datai_a <= s_tdata_u;
    u_sample <= signed(u_datao_b);
    u_addri_b <= index_u_sample;

    -- Memory to storage signal v
    v_dpram: entity work.dpram
    generic map (
      DATA_WIDTH => LBITS,
      ADDR_WIDTH => LENGHT_MAX
    )
    port map (
      clk_a   => clk,
      clk_b   => clk,
      addri_a => v_addri_a,
      datai_a => v_datai_a,
      we_a    => v_we_a,
      datao_a => v_datao_a,
      addri_b => v_addri_b,
      datai_b => v_datai_b,
      we_b    => v_we_b,
      datao_b => v_datao_b
    );

    v_we_a <= s_tvalid_v and s_tready_v;    
    v_we_b <= '0';
    v_datai_a <= s_tdata_v;
    v_sample <= signed(v_datao_b);
    v_addri_b <= index_v_sample - index_u_sample when index_v_sample >= index_u_sample else len_v + index_v_sample - index_u_sample;

    -- Counter to write/read in each port of each memory stated
    u_a_cont: entity work.contador
    generic map (
      NBITS => LENGHT_MAX   
    )
    port map (
      clk      => clk,
      rst      => reset,
      rst_sinc => reset_sinc,
      ena      => u_we_a,
      Q        => u_addri_a
    );

    v_a_cont: entity work.contador
    generic map (
      NBITS => LENGHT_MAX   
    )
    port map (
      clk      => clk,
      rst      => reset,
      rst_sinc => reset_sinc,
      ena      => v_we_a,
      Q        => v_addri_a
    );

    u_b_cont: entity work.contador
    generic map (
      NBITS => LENGHT_MAX   
    )
    port map (
      clk      => clk,
      rst      => reset,
      rst_sinc => rst_asinc_cont_u,
      ena      => u_we_b,
      Q        => u_addri_b
    );

    rst_asinc_cont_u <= '1' when reset_sinc = '1' or u_state_a = WAIT_CONV else '0';

    v_b_cont: entity work.contador
    generic map (
      NBITS => LENGHT_MAX   
    )
    port map (
      clk      => clk,
      rst      => reset,
      rst_sinc => rst_asinc_cont_v,
      ena      => v_we_b,
      Q        => v_addri_a
    );

    rst_asinc_cont_v <= '1' when reset_sinc = '1' or v_state_a = WAIT_CONV else '0';    

  -- Process to synthesize the sincronous part 
  sinc:process(clk)
  begin
    if (reset = '1') then
        v_state_a <= REPOSO;
        u_state_a <= REPOSO;
        conv_state<= REPOSO;
        index_v_sample <= (others=>'0');
        index_u_sample <= (others=>'0');
        w_sample <= (others=>'0');
    elsif (rising_edge(clk)) then
        if (reset_sinc = '1') then
            v_state_a <= REPOSO;
            u_state_a <= REPOSO;
            conv_state<= REPOSO;
            index_v_sample <= (others=>'0');
            index_u_sample <= (others=>'0');
            w_sample <= (others=>'0');
        else
            v_state_a <= p_v_state_a;
            u_state_a <= p_u_state_a;
            conv_state<= p_conv_state;
            index_v_sample <= p_index_v_sample;
            index_u_sample <= p_index_u_sample;
            w_sample <= p_w_sample;
        end if;
    end if;

  end process;

  -- Process to synthesize state machine
  u_sm_a:process(u_state_a, s_tvalid_u, u_addri_a, conv_state, len_u)
  begin
    p_u_state_a <= u_state_a;

    case u_state_a is 
        when REPOSO =>

            if s_tvalid_u = '1' and conv_state = REPOSO then
        
                p_u_state_a <= STORE;
        
            end if;
        
        when STORE =>

            if u_addri_a = len_u - 1  then
        
                p_u_state_a <= WAIT_CONV;
        
            end if;
        
        when WAIT_CONV=>

            if conv_state = REPOSO then

                p_u_state_a <= REPOSO;

            end if;

    end case;    
  end process;

  -- Process to synthesize state machine
  v_sm_a:process(v_state_a, s_tvalid_v, v_addri_a, conv_state, len_v)
  begin
    p_v_state_a <= v_state_a;

    case v_state_a is 
        when REPOSO =>

            if s_tvalid_v = '1' and conv_state = REPOSO then
        
                p_v_state_a <= STORE;
        
            end if;
        
        when STORE =>

            if v_addri_a = len_v - 1  then
        
                p_v_state_a <= WAIT_CONV;
        
            end if;
        
        when WAIT_CONV=>

            if conv_state = REPOSO then

                p_v_state_a <= REPOSO;

            end if;

    end case;    
  end process;

  conv_sm:process(conv_state, u_state_a, v_state_a, v_addri_b, len_v, u_addri_b, len_u, m_tready_w)
  begin
    p_conv_state <= conv_state;

    case conv_state is
        when REPOSO =>

        if u_state_a = WAIT_CONV and v_state_a = WAIT_CONV then
            p_conv_state <= MULT;
        end if;

        when MULT =>

            if v_addri_b = len_v - 1 then
                p_conv_state <= CONV_CALC;
            end if;

        when CONV_CALC => 
            if m_tready_w = '1' then
                p_conv_state <= MULT;
                if u_addri_b = len_u - 1 then
                    p_conv_state <= REPOSO;
                end if;
            end if;
    end case;
  end process;

  -- Calculate the lenght of the signal w
  len_u <= unsigned("0" & length_u);
  len_v <= unsigned("0" & length_v);
  length_w <= std_ulogic_vector(len_u + len_v);

  -- Process to synthesize state machine
  u_sm_a_actions:process(u_state_a,s_tvalid_u)
  begin

    s_tready_u <= '0';

    case u_state_a is 
        when REPOSO =>

            if s_tvalid_u = '1' then
                s_tready_u <= '1';
            end if;

        when STORE =>

            s_tready_u <= '1';
        
        when WAIT_CONV=>

    end case;    
  end process;  

  v_sm_a_actions:process(v_state_a,s_tvalid_v)
  begin

    s_tready_v <= '0';

    case v_state_a is 
        when REPOSO =>

            if s_tvalid_v = '1' then
                s_tready_v <= '1';
            end if;

        when STORE =>

            s_tready_v <= '1';
        
        when WAIT_CONV=>

    end case;    
  end process;  

  conv_sm_actions:process(conv_state, index_v_sample, index_u_sample, w_sample, u_state_a, v_state_a,u_sample,v_sample, m_tready_w)
  begin
    
    p_w_sample <= w_sample;
    p_index_v_sample <= index_v_sample;
    p_index_u_sample <= index_u_sample;
    m_tvalid_w <= '0';

    case conv_state is
        when REPOSO =>

            if u_state_a = WAIT_CONV and v_state_a = WAIT_CONV then
                p_index_u_sample <= index_u_sample + 1 ;
            else
                p_index_v_sample <= (others =>'0');
                p_index_u_sample <= (others =>'0');
                p_w_sample <= (others =>'0');
            end if;        

        when MULT =>

            p_index_u_sample <= index_u_sample + 1 ;
            p_w_sample <= w_sample + u_sample*v_sample*one_LENGHT_MAX;

        when CONV_CALC => 

            m_tvalid_w <= '1';
            if m_tready_w = '1' then
                p_index_v_sample <= index_v_sample + 1;
                p_index_u_sample <= (others =>'0');
            end if;

    end case;
  end process;

  m_tdata_w <= std_ulogic_vector(w_sample(LBITS-1 downto 0));

  -- Firewall assertions: assure that our module is being used correctly
  --
  -- What can go wrong?
  --
  -- 1) length_u changes while  it is storing data or calculating conv
  --
  -- 2) length_v changes while  it is storing data or calculating conv
  --
  -- An interesting idea here would be to define a procedure in
  -- edc_common.vhd called "fail_in_N_cycles", which would
  -- wait N clock cycles before stopping the simulation

  firewall_assertions: process (clk)
  begin

    if falling_edge(clk) then

        firewall_length_u <= length_u;
        firewall_length_v <= length_v;

        if u_state_a /= REPOSO or conv_state /= REPOSO then
            if (firewall_length_u /= length_u) then
                report "length_u changed while conv busy, interpolation will be wrong"
                severity failure;
            end if;
        end if;

        if v_state_a /= REPOSO or conv_state /= REPOSO then
            if (firewall_length_v /= length_v) then
                report "length_v changed while conv busy, interpolation will be wrong"
                severity failure;
            end if;
        end if;
        
    end if;
  end process;

end conv_arch;
