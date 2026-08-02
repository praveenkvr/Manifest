export interface GenerateOptions {
  system?: string;
  prompt: string;
  maxTokens?: number;
  temperature?: number;
}

export interface AIProvider {
  readonly name: string;
  generate(options: GenerateOptions): Promise<string>;
}
