
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;              -- Para manejo de texto
use ieee.std_logic_textio.all;   -- Para leer std_logic y std_logic_vector

entity conv_tb is
end;

architecture bench of conv_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant LENGHT_MAX : integer := 7;
  constant LBITS : integer := 10;
  -- Ports
  signal clk : std_ulogic;
  signal reset : std_ulogic;
  signal reset_sinc : std_ulogic;
  signal length_u : std_ulogic_vector(LENGHT_MAX-1 downto 0);
  signal length_v : std_ulogic_vector(LENGHT_MAX-1 downto 0);
  signal length_w : std_ulogic_vector(LENGHT_MAX downto 0);
  signal s_tvalid_u : std_ulogic;
  signal s_tready_u : std_ulogic;
  signal s_tdata_u : std_ulogic_vector(LBITS-1 downto 0);
  signal s_tvalid_v : std_ulogic;
  signal s_tready_v : std_ulogic;
  signal s_tdata_v : std_ulogic_vector(LBITS-1 downto 0);
  signal m_tvalid_w : std_ulogic;
  signal m_tready_w : std_ulogic;
  signal m_tdata_w : std_ulogic_vector(LBITS-1 downto 0);

begin

  conv_inst : entity work.conv
  generic map (
    LENGHT_MAX => LENGHT_MAX,
    LBITS => LBITS
  )
  port map (
    clk => clk,
    reset => reset,
    reset_sinc => reset_sinc,
    length_u => length_u,
    length_v => length_v,
    length_w => length_w,
    s_tvalid_u => s_tvalid_u,
    s_tready_u => s_tready_u,
    s_tdata_u => s_tdata_u,
    s_tvalid_v => s_tvalid_v,
    s_tready_v => s_tready_v,
    s_tdata_v => s_tdata_v,
    m_tvalid_w => m_tvalid_w,
    m_tready_w => m_tready_w,
    m_tdata_w => m_tdata_w
  );

  clk_process : process
  begin
    clk <= '1';
    wait for clk_period/2;
    clk <= '0';
    wait for clk_period/2;
  end process clk_process;

  master_u:process

    file archivo_csv : text open read_mode is "/home/salas/Escritorio/github_proyectos/VHDL_DISCREET_CONVOLUTION/test_inputs/senales_U_pulso.csv";
    variable linea      : line;
    variable valor1     : integer;

  begin
    length_u <= "1100100"; -- 100
    s_tvalid_u <= '1';
    readline(archivo_csv, linea);

    -- Leer primer número
    read(linea, valor1);

    s_tdata_u <= std_ulogic_vector(to_unsigned(valor1, LBITS));

    wait for clk_period;

    while not endfile(archivo_csv) loop

        if s_tready_u = '1' then
        readline(archivo_csv, linea);

        -- Leer primer número
        read(linea, valor1);
        s_tdata_u <= std_ulogic_vector(to_unsigned(valor1, LBITS));
        end if;

        wait for clk_period;
    end loop;

    wait ; 
    

  end process;


  master_v:process

    file archivo_csv : text open read_mode is "/home/salas/Escritorio/github_proyectos/VHDL_DISCREET_CONVOLUTION/test_inputs/senales_V_pulso.csv";
    variable linea      : line;
    variable valor1     : integer;

  begin
    length_v <= "1100100"; -- 100
    s_tvalid_v <= '1';
    readline(archivo_csv, linea);

    -- Leer primer número
    read(linea, valor1);
    s_tdata_v <= std_ulogic_vector(to_unsigned(valor1, LBITS));

    wait for clk_period;

    while not endfile(archivo_csv) loop

        if s_tready_v = '1' then
        readline(archivo_csv, linea);

        -- Leer primer número
        read(linea, valor1);
        s_tdata_v <= std_ulogic_vector(to_unsigned(valor1, LBITS));
        end if;

        wait for clk_period;
    end loop;

    wait ; 
    

  end process;

  slave_w:process

    file archivo_csv : text open write_mode  is "/home/salas/Escritorio/github_proyectos/VHDL_DISCREET_CONVOLUTION/test_outputs/senal_w.csv";
    variable linea      : line;
    variable valor1     : integer;
    variable contador: integer;

  begin

    m_tready_w <= '1';
    while contador < to_integer(unsigned(length_u)) + to_integer(unsigned(length_v)) - 1 loop

        if m_tvalid_w = '1' then

        valor1 := to_integer(unsigned(m_tdata_w));  
        write(linea, valor1);
        writeline(archivo_csv, linea);
        contador := contador +1;
        end if;

        wait for clk_period;
    end loop;

    wait ; 
    

  end process;

end;